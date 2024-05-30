package net.sourceforge.pmd.buildtools.surefire.junit;

import static org.junit.platform.engine.discovery.DiscoverySelectors.selectClass;

import java.lang.reflect.InvocationTargetException;

import org.apache.maven.surefire.api.provider.AbstractProvider;
import org.apache.maven.surefire.api.provider.ProviderParameters;
import org.apache.maven.surefire.api.report.ReporterException;
import org.apache.maven.surefire.api.report.ReporterFactory;
import org.apache.maven.surefire.api.report.TestOutputReportEntry;
import org.apache.maven.surefire.api.report.TestReportListener;
import org.apache.maven.surefire.api.suite.RunResult;
import org.apache.maven.surefire.api.testset.TestListResolver;
import org.apache.maven.surefire.api.testset.TestSetFailedException;
import org.apache.maven.surefire.api.util.ScanResult;
import org.apache.maven.surefire.api.util.TestsToRun;
import org.junit.platform.engine.FilterResult;
import org.junit.platform.engine.discovery.ClassNameFilter;
import org.junit.platform.launcher.Launcher;
import org.junit.platform.launcher.LauncherSession;
import org.junit.platform.launcher.TestPlan;
import org.junit.platform.launcher.core.LauncherDiscoveryRequestBuilder;
import org.junit.platform.launcher.core.LauncherFactory;

/**
 * A Surefire Provider for JUnit Platform. It reports only one test set per test class,
 * uses the UniqueId of the test cases to identify single test cases (as opposed to use
 * methods names, which are not available by Kotest).
 *
 * <p>It reports any test class, which doesn't contain test cases, as failed. This
 * indicates a problem in the test setup.
 */
public class JUnitPlatformProvider extends AbstractProvider {
    private final ProviderParameters parameters;

    public JUnitPlatformProvider(ProviderParameters parameters) {
        this.parameters = parameters;
    }

    @Override
    public Iterable<Class<?>> getSuites() {
        try (LauncherSession session = LauncherFactory.openSession()) {
            return findTests(session);
        }
    }

    @Override
    public RunResult invoke(Object forkTestSet) throws TestSetFailedException, ReporterException, InvocationTargetException {
        ReporterFactory reporterFactory = parameters.getReporterFactory();

        final RunResult result;
        try (LauncherSession session = LauncherFactory.openSession()) {
            final TestsToRun testsToRun;
            if (forkTestSet instanceof TestsToRun) {
                testsToRun = (TestsToRun) forkTestSet;
            } else if (forkTestSet instanceof Class) {
                testsToRun = TestsToRun.fromClass((Class<?>) forkTestSet);
            } else if (forkTestSet == null) {
                testsToRun = findTests(session);
            } else {
                throw new IllegalArgumentException("Invalid forkTestSet parameter: " + forkTestSet);
            }

            runTests(session, testsToRun, reporterFactory.createTestReportListener());

        } finally {
            result = reporterFactory.close();
        }

        return result;
    }

    private void runTests(LauncherSession session, TestsToRun testsToRun, TestReportListener<TestOutputReportEntry> testReportListener) {
        Launcher launcher = session.getLauncher();
        testsToRun.iterator().forEachRemaining(testClass -> {
            TestPlan testPlan = launcher.discover(LauncherDiscoveryRequestBuilder.request()
                    .selectors(selectClass(testClass))
                    .build());
            launcher.execute(testPlan, new TestExecutionListener(testReportListener));
        });
    }

    /**
     * Determines the tests to run - taking {@code -Dtest=...} param into account.
     */
    private TestsToRun findTests(LauncherSession session) {
        ScanResult scanResult = parameters.getScanResult();
        TestListResolver testListResolver = parameters.getTestRequest().getTestListResolver();
        return scanResult.applyFilter(testClass -> {
            TestPlan testPlan = session.getLauncher().discover(
                    LauncherDiscoveryRequestBuilder.request()
                            .selectors(selectClass(testClass))
                            .filters((ClassNameFilter) className -> {
                                String classFileName = TestListResolver.toClassFileName(className);
                                boolean shouldRun = testListResolver.shouldRun(classFileName, null);
                                return FilterResult.includedIf(shouldRun);
                            })
                            .build()
            );
            return testPlan.containsTests();
        }, parameters.getTestClassLoader());
    }
}
