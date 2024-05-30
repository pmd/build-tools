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
import org.junit.platform.engine.support.descriptor.ClassSource;
import org.junit.platform.engine.support.descriptor.MethodSource;
import org.junit.platform.launcher.TestIdentifier;

class TestExecutionListener implements org.junit.platform.launcher.TestExecutionListener, TestOutputReceiver<OutputReportEntry> {
    private final AtomicLong testIdGenerator = new AtomicLong();
    private final Map<String, Long> testIdMapping = new ConcurrentHashMap<>();
    private final ThreadLocal<Long> currentRunId = new ThreadLocal<>();
    private final ConcurrentMap<String, RootContainer> rootContainers = new ConcurrentHashMap<>();

    private final TestReportListener<TestOutputReportEntry> testReportListener;

    public TestExecutionListener(TestReportListener<TestOutputReportEntry> testReportListener) {
        this.testReportListener = testReportListener;
    }

    @Override
    public void executionSkipped(TestIdentifier testIdentifier, String reason) {
        determineRootContainer(testIdentifier).ifPresent(RootContainer::markHasAtLeastOneTest);
        testReportListener.testSkipped(toReportEntry(testIdentifier));
    }

    @Override
    public void executionStarted(TestIdentifier testIdentifier) {
        if (testIdentifier.isContainer()) {
            Optional<String> rootClass = determineRootClass(testIdentifier);
            if (rootClass.isPresent()) {
                RootContainer previous = rootContainers.putIfAbsent(rootClass.get(), new RootContainer(testIdentifier));
                if (previous == null) {
                    testReportListener.testSetStarting(toTestSetReportEntry(testIdentifier));
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

        if (testIdentifier.isContainer()) {
            Optional<String> rootClass = determineRootClass(testIdentifier);
            Optional<RootContainer> rootContainer = determineRootContainer(testIdentifier);
            if (rootClass.isPresent() && rootContainer.isPresent()) {
                if (rootContainer.get().isIdentifier(testIdentifier)) {
                    RootContainer removed = rootContainers.remove(rootClass.get());
                    if (removed != null) {
                        if (removed.hasNoTests()) {
                            String message = "No Tests have been executed in Test Set";
                            testReportListener.testError(toReportEntry(testIdentifier, message, new IllegalStateException(message), Collections.emptyMap()));
                        }
                        testReportListener.testSetCompleted(toTestSetReportEntry(testIdentifier));
                    }
                }
            }
        } else {
            String message = testExecutionResult.getThrowable().map(Throwable::getMessage).orElse(null);
            boolean isAssertionError = testExecutionResult.getThrowable().map(AssertionError.class::isInstance).orElse(false);
            SimpleReportEntry reportEntry = toReportEntry(testIdentifier, message,
                    testExecutionResult.getThrowable().orElse(null), systemProps);

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

        if (classNameFromMethodSource.isPresent()) {
            return classNameFromMethodSource;
        }
        return classNameFromClassSource;
    }

    private Optional<RootContainer> determineRootContainer(TestIdentifier testIdentifier) {
        return determineRootClass(testIdentifier).map(rootContainers::get);
    }

    private SimpleReportEntry toReportEntry(TestIdentifier testIdentifier) {
        return toReportEntry(testIdentifier, null, null, Collections.emptyMap());
    }

    private SimpleReportEntry toReportEntry(TestIdentifier testIdentifier, String message, Throwable throwable,
                                            Map<String, String> systemProps) {
        return new SimpleReportEntry(
                RunMode.NORMAL_RUN,
                determineRunId(testIdentifier),
                testIdentifier.getDisplayName(),
                testIdentifier.getDisplayName(),
                testIdentifier.getUniqueId(),
                testIdentifier.getUniqueId(),
                new LegacyPojoStackTraceWriter(testIdentifier.getDisplayName(), null, throwable),
                0,
                message,
                systemProps
        );
    }

    private SimpleReportEntry toTestSetReportEntry(TestIdentifier testIdentifier) {
        return new SimpleReportEntry(
                RunMode.NORMAL_RUN,
                determineRunId(testIdentifier),
                testIdentifier.getDisplayName(),
                testIdentifier.getDisplayName(),
                null, null
        );
    }

    @Override
    public void writeTestOutput(OutputReportEntry reportEntry) {
        Long testRunId = currentRunId.get();
        testReportListener.writeTestOutput(new TestOutputReportEntry(reportEntry, RunMode.NORMAL_RUN, testRunId));
    }
}
