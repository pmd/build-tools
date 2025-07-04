/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire.junit;

import java.lang.management.ManagementFactory;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicLong;

import org.apache.maven.surefire.api.report.LegacyPojoStackTraceWriter;
import org.apache.maven.surefire.api.report.OutputReportEntry;
import org.apache.maven.surefire.api.report.RunMode;
import org.apache.maven.surefire.api.report.SimpleReportEntry;
import org.apache.maven.surefire.api.report.TestOutputReceiver;
import org.apache.maven.surefire.api.report.TestOutputReportEntry;
import org.apache.maven.surefire.api.report.TestReportListener;
import org.junit.platform.engine.TestExecutionResult;
import org.junit.platform.engine.UniqueId;
import org.junit.platform.engine.support.descriptor.ClassSource;
import org.junit.platform.engine.support.descriptor.MethodSource;
import org.junit.platform.launcher.TestIdentifier;

class TestExecutionListener implements org.junit.platform.launcher.TestExecutionListener, TestOutputReceiver<OutputReportEntry> {
    private final AtomicLong testIdGenerator = new AtomicLong();
    private final Map<String, Long> testIdMapping = new ConcurrentHashMap<>();
    private final ThreadLocal<Long> currentRunId = new ThreadLocal<>();
    private final ConcurrentMap<String, RootContainer> rootContainers = new ConcurrentHashMap<>();
    private final ConcurrentMap<TestIdentifier, Long> startTimes = new ConcurrentHashMap<>();

    private final TestReportListener<TestOutputReportEntry> testReportListener;

    TestExecutionListener(TestReportListener<TestOutputReportEntry> testReportListener) {
        this.testReportListener = testReportListener;
    }

    @Override
    public void executionSkipped(TestIdentifier testIdentifier, String reason) {
        determineRootContainer(testIdentifier).ifPresent(RootContainer::markHasAtLeastOneTest);
        testReportListener.testSkipped(toReportEntry(testIdentifier));
    }

    @Override
    public void executionStarted(TestIdentifier testIdentifier) {
        startTimes.put(testIdentifier, System.currentTimeMillis());
        if (testIdentifier.isContainer()) {
            Optional<String> rootClass = determineRootClass(testIdentifier);
            if (rootClass.isPresent()) {
                RootContainer previous = rootContainers.putIfAbsent(rootClass.get(), new RootContainer(testIdentifier));
                if (previous == null) {
                    testReportListener.testSetStarting(toTestSetReportEntry(testIdentifier, null));
                }
            }
        } else {
            SimpleReportEntry reportEntry = toReportEntry(testIdentifier);
            testReportListener.testStarting(reportEntry);
        }
    }

    @Override
    public void executionFinished(TestIdentifier testIdentifier, TestExecutionResult testExecutionResult) {
        Map<String, String> systemProps = ManagementFactory.getRuntimeMXBean().getSystemProperties();
        Long startTime = startTimes.remove(testIdentifier);
        Integer elapsed = null;
        if (startTime != null) {
            elapsed = (int) (System.currentTimeMillis() - startTime);
        }

        if (testIdentifier.isContainer()) {
            Optional<String> rootClass = determineRootClass(testIdentifier);
            Optional<RootContainer> rootContainer = determineRootContainer(testIdentifier);
            if (rootClass.isPresent() && rootContainer.isPresent()) {
                if (rootContainer.get().isIdentifier(testIdentifier)) {
                    RootContainer removed = rootContainers.remove(rootClass.get());
                    if (removed != null) {
                        if (removed.hasNoTests()) {
                            String message = "No Tests have been executed in Test Set";
                            testReportListener.testError(toReportEntry(testIdentifier, message,
                                    new IllegalStateException(message), Collections.emptyMap(), null));
                        }
                        testReportListener.testSetCompleted(toTestSetReportEntry(testIdentifier, elapsed));
                    }
                }
            }
        } else {
            String message = testExecutionResult.getThrowable().map(Throwable::getMessage).orElse(null);
            boolean isAssertionError = testExecutionResult.getThrowable().map(AssertionError.class::isInstance).orElse(false);
            SimpleReportEntry reportEntry = toReportEntry(testIdentifier, message,
                    testExecutionResult.getThrowable().orElse(null), systemProps, elapsed);

            determineRootContainer(testIdentifier).ifPresent(RootContainer::markHasAtLeastOneTest);
            switch (testExecutionResult.getStatus()) {
            case SUCCESSFUL:
                testReportListener.testSucceeded(reportEntry);
                break;
            case FAILED:
                if (isAssertionError) {
                    testReportListener.testFailed(reportEntry);
                } else {
                    testReportListener.testError(reportEntry);
                }
                break;
            case ABORTED:
                testReportListener.testAssumptionFailure(reportEntry);
                break;
            default:
                throw new IllegalStateException("Unknown execution result status: " + testExecutionResult.getStatus());
            }
        }
    }

    private long determineRunId(TestIdentifier testIdentifier) {
        return testIdMapping.computeIfAbsent(testIdentifier.getUniqueId(), (id) -> {
            long runId = testIdGenerator.incrementAndGet();
            currentRunId.set(runId);
            return runId;
        });
    }

    private Optional<String> determineRootClass(TestIdentifier testIdentifier) {
        Optional<String> classNameFromClassSource = testIdentifier.getSource()
                .filter(ClassSource.class::isInstance)
                .map(ClassSource.class::cast)
                .map(ClassSource::getClassName);
        Optional<String> classNameFromMethodSource = testIdentifier.getSource()
                .filter(MethodSource.class::isInstance)
                .map(MethodSource.class::cast)
                .map(MethodSource::getClassName);
        Optional<String> classNameFromUniqueId = testIdentifier.getUniqueIdObject()
                .getSegments().stream()
                .filter(s -> "class".equals(s.getType()))
                .map(UniqueId.Segment::getValue)
                .findFirst();

        if (classNameFromMethodSource.isPresent()) {
            return classNameFromMethodSource;
        }
        if (classNameFromClassSource.isPresent()) {
            return classNameFromClassSource;
        }
        return classNameFromUniqueId;
    }

    private Optional<RootContainer> determineRootContainer(TestIdentifier testIdentifier) {
        return determineRootClass(testIdentifier).map(rootContainers::get);
    }

    private SimpleReportEntry toReportEntry(TestIdentifier testIdentifier) {
        return toReportEntry(testIdentifier, null, null, Collections.emptyMap(), null);
    }

    private SimpleReportEntry toReportEntry(TestIdentifier testIdentifier, String message, Throwable throwable,
                                            Map<String, String> systemProps, Integer elapsed) {
        return new SimpleReportEntry(
                RunMode.NORMAL_RUN,
                determineRunId(testIdentifier),
                testIdentifier.getDisplayName(),
                testIdentifier.getDisplayName(),
                testIdentifier.getUniqueId(),
                testIdentifier.getUniqueId(),
                throwable != null ? new LegacyPojoStackTraceWriter(testIdentifier.getDisplayName(), null, throwable) : null,
                elapsed,
                message,
                systemProps
        );
    }

    private SimpleReportEntry toTestSetReportEntry(TestIdentifier testIdentifier, Integer elapsed) {
        String testClass = determineRootClass(testIdentifier).orElse(testIdentifier.getDisplayName());
        return new SimpleReportEntry(
                RunMode.NORMAL_RUN,
                determineRunId(testIdentifier),
                testClass,
                testIdentifier.getDisplayName(),
                null, null, elapsed
        );
    }

    @Override
    public void writeTestOutput(OutputReportEntry reportEntry) {
        Long testRunId = currentRunId.get();
        testReportListener.writeTestOutput(new TestOutputReportEntry(reportEntry, RunMode.NORMAL_RUN, testRunId));
    }
}
