/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire;

import java.util.Collection;
import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.maven.plugin.surefire.log.api.ConsoleLogger;
import org.apache.maven.plugin.surefire.report.TestSetStats;
import org.apache.maven.plugin.surefire.report.WrappedReportEntry;
import org.apache.maven.surefire.api.report.TestSetReportEntry;
import org.apache.maven.surefire.extensions.StatelessTestsetInfoConsoleReportEventListener;
import org.apache.maven.surefire.shared.utils.logging.MessageBuilder;
import org.apache.maven.surefire.shared.utils.logging.MessageUtils;

class AccumulatingConsoleReporter extends StatelessTestsetInfoConsoleReportEventListener<WrappedReportEntry, TestSetStats> {
    private final boolean showSuccessfulTests;

    private final boolean showFailedTests;

    private final boolean showSkippedTests;

    public AccumulatingConsoleReporter(ConsoleLogger logger, boolean showSuccessfulTests, boolean showFailedTests, boolean showSkippedTests) {
        super(logger);
        this.showSuccessfulTests = showSuccessfulTests;
        this.showFailedTests = showFailedTests;
        this.showSkippedTests = showSkippedTests;
    }

    private final Map<String, Deque<String>> nestedTestSetNames = new HashMap<>();
    private final Map<String, TestSetStats> accumulatedTestSetStats = new HashMap<>();
    private final Map<String, Integer> totalElapsedTimeMillis = new HashMap<>();

    @Override
    public void testSetStarting(TestSetReportEntry report) {
        String source = getOuterTestClass(report);
        if (!nestedTestSetNames.containsKey(source)) {
            nestedTestSetNames.put(source, new LinkedList<String>());
        }
        Deque<String> nesting = nestedTestSetNames.get(source);
        if (nesting.isEmpty()) {
            nesting.addLast(source);
            accumulatedTestSetStats.put(source, new TestSetStats(true, true));
            totalElapsedTimeMillis.put(source, 0);
            MessageBuilder buffer = MessageUtils.buffer();
            getConsoleLogger().info("Running " + buffer.strong(source));
        } else {
            String fullName = report.getSourceText();
            if (fullName == null) {
                fullName = report.getSourceName();
            }
            fullName = fullName.replaceAll("\\$", " ");
            nesting.addLast(fullName);
        }
    }

    @Override
    public void testSetCompleted(WrappedReportEntry report, TestSetStats testSetStats, List<String> testResults) {
        String outerTestClass = getOuterTestClass(report);
        Deque<String> nesting = nestedTestSetNames.get(outerTestClass);

        int elapsedMillis = totalElapsedTimeMillis.get(outerTestClass) + report.getElapsed();
        totalElapsedTimeMillis.put(outerTestClass, elapsedMillis);

        TestSetStats accumulated = accumulatedTestSetStats.get(outerTestClass);
        accumulateTestSetStats(accumulated, testSetStats.getReportEntries());

        String prefix = "└─ ";
        if ((testSetStats.getErrors() > 0 || testSetStats.getFailures() > 0) && showFailedTests
            || testSetStats.getSkipped() > 0 && showSkippedTests
            || testSetStats.getCompletedCount() > 0 && showSuccessfulTests) {
            if (!testSetStats.getReportEntries().isEmpty() && nesting.size() > 1) {
                String previousTestSetName = null;
                for (String fullTestSetName : nesting) {
                    if (previousTestSetName != null) {
                        prefix = "    " + prefix;
                        String shortenedTestSetName = fullTestSetName;
                        if (fullTestSetName.startsWith(previousTestSetName)) {
                            shortenedTestSetName = fullTestSetName.substring(previousTestSetName.length());
                        }
                        getConsoleLogger().info(prefix + shortenedTestSetName);
                    }
                    previousTestSetName = fullTestSetName + " ";
                }
            }
        }

        String testSetName = getTestSetName(report);
        // individual tests
        for (WrappedReportEntry entry : testSetStats.getReportEntries()) {
            String shortTestCaseName = getTestCaseName(entry, testSetName);
            MessageBuilder buffer = MessageUtils.buffer();
            if (entry.isErrorOrFailure() && showFailedTests) {
                buffer.failure("✘ ").failure(shortTestCaseName);
                getConsoleLogger().info("    " + prefix + buffer);
            } else if (entry.isSkipped() && showSkippedTests) {
                buffer.warning("↷ ").warning(shortTestCaseName);
                getConsoleLogger().info("    " + prefix + buffer);
            } else if (showSuccessfulTests) {
                buffer.success("✔ ").a(shortTestCaseName);
                getConsoleLogger().info("    " + prefix + buffer);
            }
        }

        if (nesting.size() == 1) {
            WrappedReportEntry reportWithTotalElapsedMillis = new WrappedReportEntry(report,
                    report.getReportEntryType(), elapsedMillis, null, null);
            getConsoleLogger().info(accumulated.getColoredTestSetSummary(reportWithTotalElapsedMillis, false));

            accumulatedTestSetStats.remove(outerTestClass);
            nestedTestSetNames.remove(outerTestClass);
            totalElapsedTimeMillis.remove(outerTestClass);
        } else {
            nesting.pollLast();
        }
    }

    private static String getTestSetName(WrappedReportEntry report) {
        String testSetName = report.getSourceText();
        if (testSetName == null) {
            testSetName = report.getSourceName();
        }
        return testSetName;
    }

    private static String getTestCaseName(WrappedReportEntry entry, String testSetName) {
        String testCaseName = entry.getNameText();
        if (testCaseName == null) {
            testCaseName = entry.getName();
        }
        if (testCaseName == null) {
            testCaseName = getTestSetName(entry);
        }

        String shortenedTestCaseName = testCaseName;
        if (testCaseName.startsWith(testSetName)) {
            shortenedTestCaseName = testCaseName.substring(testSetName.length());
        }
        if (shortenedTestCaseName.isEmpty()) {
            shortenedTestCaseName = "[unnamed test case]";
        }

        return shortenedTestCaseName;
    }

    private static void accumulateTestSetStats(TestSetStats accumulated, Collection<WrappedReportEntry> reportEntries) {
        for (WrappedReportEntry entry : reportEntries) {
            switch (entry.getReportEntryType()) {
                case SUCCESS:
                    accumulated.testSucceeded(entry);
                    break;
                case SKIPPED:
                    accumulated.testSkipped(entry);
                    break;
                case FAILURE:
                    accumulated.testFailure(entry);
                    break;
                case ERROR:
                    accumulated.testError(entry);
                    break;
            }
        }
    }

    @Override
    public void reset() {
    }

    private static String getOuterTestClass(TestSetReportEntry report) {
        String source = report.getSourceName();
        int dollar = source.indexOf('$');
        if (dollar != -1) {
            source = source.substring(0, dollar);
        }
        return source;
    }
}
