/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.apache.maven.plugin.surefire.report.ReportEntryType;
import org.apache.maven.plugin.surefire.report.TestSetStats;
import org.apache.maven.plugin.surefire.report.WrappedReportEntry;
import org.apache.maven.surefire.api.report.RunMode;
import org.apache.maven.surefire.api.report.SimpleReportEntry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

public class AccumulatingConsoleReporterTest {
    private static long testRunId = 1L;

    private static final List<String> EMPTY = new ArrayList<>();
    private static final TestSetStats EMPTY_STATS = new TestSetStats(true, true);
    private static final String NL = System.lineSeparator();

    private MockedConsoleLogger logger;
    private AccumulatingConsoleReporter reporter;
    @BeforeEach
    void setup() {
        logger = new MockedConsoleLogger();
        reporter = new AccumulatingConsoleReporter(logger, false, true, true);
    }


    @Test
    void testSimpleJUnitTestSuccess() {
        SimpleReportEntry testSet = createTestSet("net.sourceforge.pmd.test.Simple");
        SimpleReportEntry testCase = createTestCase(testSet, "testMethod");

        TestSetStats testSetStats = new TestSetStats(true, true);
        testSetStats.testSucceeded(new WrappedReportEntry(testCase, ReportEntryType.SUCCESS, 120, null, null));
        WrappedReportEntry wrappedReportEntry = new WrappedReportEntry(testSet, ReportEntryType.SUCCESS, 123, null, null);

        reporter.testSetStarting(testSet);
        reporter.testSetCompleted(wrappedReportEntry, testSetStats, EMPTY);

        logger.assertInfoContains("Running net.sourceforge.pmd.test.Simple");
        logger.assertInfoContains("Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.123 s - in net.sourceforge.pmd.test.Simple");
    }

    @Test
    void testSimpleJUnitTestFailure() {
        SimpleReportEntry testSet = createTestSet("net.sourceforge.pmd.test.Simple");
        SimpleReportEntry testCase = createTestCase(testSet, "testFail");

        TestSetStats testSetStats = new TestSetStats(true, true);
        testSetStats.testFailure(new WrappedReportEntry(testCase, ReportEntryType.FAILURE, 1, null, null));
        WrappedReportEntry wrappedReportEntry = new WrappedReportEntry(testSet, null, 1, null, null);

        reporter.testSetStarting(testSet);
        reporter.testSetCompleted(wrappedReportEntry, testSetStats, Arrays.asList("Stacktrace..."));

        logger.assertInfo(
                "Running net.sourceforge.pmd.test.Simple" + NL
                 + "    └─ ✘ testFail" + NL
                 + "Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.001 s <<< FAILURE! - in net.sourceforge.pmd.test.Simple" + NL);
        logger.assertError("Stacktrace..." + NL);
    }

    @Test
    void testNestedTestSets() {
        SimpleReportEntry testSet = createTestSet("net.sourceforge.pmd.test.Simple");
        SimpleReportEntry testSetNested = createTestSet("net.sourceforge.pmd.test.Simple", "net.sourceforge.pmd.test.Simple Nested Group 1");
        SimpleReportEntry testSetNested2 = createTestSet("net.sourceforge.pmd.test.Simple", "net.sourceforge.pmd.test.Simple Nested Group 1 Another Level");
        SimpleReportEntry testCase = createTestCaseKotest(testSetNested2, "net.sourceforge.pmd.test.Simple Nested Group 1 Another Level The actual test case name");

        TestSetStats testSetStats = new TestSetStats(true, true);
        testSetStats.testFailure(new WrappedReportEntry(testCase, ReportEntryType.FAILURE, 1, null, null));
        WrappedReportEntry wrappedTestSetNested2 = new WrappedReportEntry(testSetNested2, ReportEntryType.FAILURE, 1, null, null);
        WrappedReportEntry wrappedTestSetNested = new WrappedReportEntry(testSetNested, ReportEntryType.FAILURE, 1, null, null);
        WrappedReportEntry wrappedTestSet = new WrappedReportEntry(testSet, ReportEntryType.FAILURE, 1, null, null);

        reporter.testSetStarting(testSet);
        reporter.testSetStarting(testSetNested);
        reporter.testSetStarting(testSetNested2);
        reporter.testSetCompleted(wrappedTestSetNested2, testSetStats, EMPTY);
        reporter.testSetCompleted(wrappedTestSetNested, EMPTY_STATS, EMPTY);
        reporter.testSetCompleted(wrappedTestSet, EMPTY_STATS, EMPTY);

        logger.assertInfo(
                "Running net.sourceforge.pmd.test.Simple" + NL
                 + "    └─ Nested Group 1" + NL
                 + "        └─ Another Level" + NL
                 + "            └─ ✘  The actual test case name" + NL
                 + "Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.003 s <<< FAILURE! - in net.sourceforge.pmd.test.Simple" + NL
        );
    }

    @Test
    void testNestedTestSetsUnnamed() {
        SimpleReportEntry testSet = createTestSet("net.sourceforge.pmd.test.Simple");
        SimpleReportEntry testSetNested = createTestSet("net.sourceforge.pmd.test.Simple", "net.sourceforge.pmd.test.Simple Nested Group 1");
        SimpleReportEntry testSetNested2 = createTestSet("net.sourceforge.pmd.test.Simple", "net.sourceforge.pmd.test.Simple Nested Group 1 Another Level");
        SimpleReportEntry testCase = createTestCaseKotest(testSetNested2, "net.sourceforge.pmd.test.Simple Nested Group 1 Another Level");

        TestSetStats testSetStats = new TestSetStats(true, true);
        testSetStats.testFailure(new WrappedReportEntry(testCase, ReportEntryType.FAILURE, 1, null, null));
        WrappedReportEntry wrappedTestSetNested2 = new WrappedReportEntry(testSetNested2, ReportEntryType.FAILURE, 1, null, null);
        WrappedReportEntry wrappedTestSetNested = new WrappedReportEntry(testSetNested, ReportEntryType.FAILURE, 1, null, null);
        WrappedReportEntry wrappedTestSet = new WrappedReportEntry(testSet, ReportEntryType.FAILURE, 1, null, null);

        reporter.testSetStarting(testSet);
        reporter.testSetStarting(testSetNested);
        reporter.testSetStarting(testSetNested2);
        reporter.testSetCompleted(wrappedTestSetNested2, testSetStats, EMPTY);
        reporter.testSetCompleted(wrappedTestSetNested, EMPTY_STATS, EMPTY);
        reporter.testSetCompleted(wrappedTestSet, EMPTY_STATS, EMPTY);

        logger.assertInfo(
                "Running net.sourceforge.pmd.test.Simple" + NL
                        + "    └─ Nested Group 1" + NL
                        + "        └─ Another Level" + NL
                        + "            └─ ✘ [unnamed test case]" + NL
                        + "Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.003 s <<< FAILURE! - in net.sourceforge.pmd.test.Simple" + NL
        );
    }

    private SimpleReportEntry createTestSet(String className) {
        return createTestSet(className, null);
    }
    private SimpleReportEntry createTestSet(String className, String sourceText) {
        return new SimpleReportEntry(RunMode.NORMAL_RUN, testRunId++, className, sourceText, null, null);
    }
    private SimpleReportEntry createTestCase(SimpleReportEntry testSet, String methodName) {
        return new SimpleReportEntry(RunMode.NORMAL_RUN, testRunId++, testSet.getSourceName(), null, methodName, null);
    }
    private SimpleReportEntry createTestCaseKotest(SimpleReportEntry testSet, String sourceText) {
        return new SimpleReportEntry(RunMode.NORMAL_RUN, testRunId++, testSet.getSourceName(), sourceText, null, null);
    }
}
