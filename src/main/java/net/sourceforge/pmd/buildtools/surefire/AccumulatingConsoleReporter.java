/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire;

import java.util.ArrayDeque;
import java.util.Collection;
import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.maven.plugin.surefire.log.api.ConsoleLogger;
import org.apache.maven.plugin.surefire.report.TestSetStats;
import org.apache.maven.plugin.surefire.report.WrappedReportEntry;
import org.apache.maven.surefire.api.report.ReportEntry;
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

    private final Deque<ReportEntry> testSets = new ArrayDeque<>();
    private final Map<ReportEntry, TestSetStats> accStats = new HashMap<>();
    private final Map<ReportEntry, Integer> accTime = new HashMap<>();

    private final Map<String, Deque<String>> nestedTestSetNames = new HashMap<>();
    private final Map<String, TestSetStats> accumulatedTestSetStats = new HashMap<>();
    private final Map<String, Integer> totalElapsedTimeMillis = new HashMap<>();
    private final Map<String, List<String>> accumulatedTestResults = new HashMap<>();

    @Override
    public void testSetStarting(TestSetReportEntry report) {
        testSets.addLast(report);
        accStats.put(report, new TestSetStats(true, true));
        accTime.put(report, 0);
        boolean isNested = testSets.size() > 1;
        String prefix = isNested ? "    " : "";

        String outerTestClass = getOuterTestClass(report);
        if (!nestedTestSetNames.containsKey(outerTestClass)) {
            nestedTestSetNames.put(outerTestClass, new LinkedList<String>());
        }
        Deque<String> nesting = nestedTestSetNames.get(outerTestClass);
        if (nesting.isEmpty()) {
            nesting.addLast(outerTestClass);
            accumulatedTestSetStats.put(outerTestClass, new TestSetStats(true, true));
            totalElapsedTimeMillis.put(outerTestClass, 0);
            accumulatedTestResults.put(outerTestClass, new LinkedList<String>());
            MessageBuilder buffer = MessageUtils.buffer();
            getConsoleLogger().info(prefix + "Running " + buffer.strong(outerTestClass));
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

        boolean isNested = testSets.size() > 1;
        String indentation = isNested ? "    " : "";

        if (isNested) {
            TestSetStats acc  = accStats.get(testSets.peekFirst());
            accumulateTestSetStats(acc, testSetStats.getReportEntries());

            int time = accTime.get(testSets.peekFirst()) + report.getElapsed();
            accTime.put(testSets.peekFirst(), time);
        } else {
            accumulated = accStats.get(testSets.peekFirst());
            accumulateTestSetStats(accumulated, testSetStats.getReportEntries());
            elapsedMillis = accTime.get(testSets.peekFirst()) + report.getElapsed();
        }
        ReportEntry finishedReport = testSets.removeLast();
        accStats.remove(finishedReport);
        accTime.remove(finishedReport);

        accumulatedTestResults.get(outerTestClass).addAll(testResults);

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

        if (nesting.size() == 1) {
            prefix = indentation + prefix;
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
            getConsoleLogger().info(indentation + accumulated.getColoredTestSetSummary(reportWithTotalElapsedMillis, false));

            printTestResults(accumulated, accumulatedTestResults.get(outerTestClass));

            accumulatedTestSetStats.remove(outerTestClass);
            nestedTestSetNames.remove(outerTestClass);
            totalElapsedTimeMillis.remove(outerTestClass);
            accumulatedTestResults.remove(outerTestClass);
        } else {
            nesting.pollLast();
        }
    }

    private void printTestResults(TestSetStats accumulated, List<String> testResults) {
        if (accumulated.getErrors() > 0 || accumulated.getFailures() > 0) {
            for (String line : testResults) {
                getConsoleLogger().error(line);
            }
        } else if (accumulated.getSkipped() > 0) {
            for (String line : testResults) {
                getConsoleLogger().warning(line);
            }
        } else {
            for (String line : testResults) {
                getConsoleLogger().info(line);
            }
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
