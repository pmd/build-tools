package net.sourceforge.pmd.buildtools.surefire.junit;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.apache.maven.surefire.api.report.ReportEntry;
import org.apache.maven.surefire.api.report.TestOutputReportEntry;
import org.apache.maven.surefire.api.report.TestReportListener;
import org.apache.maven.surefire.api.report.TestSetReportEntry;
import org.junit.jupiter.api.Test;
import org.junit.platform.engine.TestDescriptor;
import org.junit.platform.engine.TestExecutionResult;
import org.junit.platform.engine.TestSource;
import org.junit.platform.engine.TestTag;
import org.junit.platform.engine.UniqueId;
import org.junit.platform.engine.support.descriptor.ClassSource;
import org.junit.platform.engine.support.descriptor.MethodSource;
import org.junit.platform.launcher.TestIdentifier;

class TestExecutionListenerTest {

    @Test
    void singleTest() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet = new MyTestDescriptor("MyTestClass");
        TestDescriptor testCase = new MyTestDescriptor("MyTestClass", "myTest");

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet));
        listener.executionStarted(TestIdentifier.from(testCase));
        listener.executionFinished(TestIdentifier.from(testCase), TestExecutionResult.successful());
        listener.executionFinished(TestIdentifier.from(testSet), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(1, 1, 0);
    }

    @Test
    void skippedTest() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet = new MyTestDescriptor("MyTestClass");
        TestDescriptor testCase1 = new MyTestDescriptor("MyTestClass", "myTest");
        TestDescriptor testCase2 = new MyTestDescriptor("MyTestClass", "myTestSkipped");

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet));
        listener.executionStarted(TestIdentifier.from(testCase1));
        listener.executionFinished(TestIdentifier.from(testCase1), TestExecutionResult.successful());
        listener.executionSkipped(TestIdentifier.from(testCase2), "reason");
        listener.executionFinished(TestIdentifier.from(testSet), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(1, 1, 0, 0, 1);
    }

    @Test
    void errorForEmptyTestSet() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet = new MyTestDescriptor("MyTestClass");

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet));
        listener.executionFinished(TestIdentifier.from(testSet), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(0, 0, 0, 1, 0);
    }

    @Test
    void failedTest() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet = new MyTestDescriptor("MyTestClass");
        TestDescriptor testCase1 = new MyTestDescriptor("MyTestClass", "myTest");

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet));
        listener.executionStarted(TestIdentifier.from(testCase1));
        listener.executionFinished(TestIdentifier.from(testCase1), TestExecutionResult.failed(new AssertionError("test")));
        listener.executionFinished(TestIdentifier.from(testSet), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(1, 0, 1);
    }

    @Test
    void erroredTest() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet = new MyTestDescriptor("MyTestClass");
        TestDescriptor testCase1 = new MyTestDescriptor("MyTestClass", "myTest");

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet));
        listener.executionStarted(TestIdentifier.from(testCase1));
        listener.executionFinished(TestIdentifier.from(testCase1), TestExecutionResult.failed(new RuntimeException("test")));
        listener.executionFinished(TestIdentifier.from(testSet), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(1, 0, 0, 1, 0);
    }

    @Test
    void nestedTestSets() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet1 = new MyTestDescriptor("MyTestClass");
        TestDescriptor testSet2 = new MyTestDescriptor("MyTestClass", new String[] {"nesting"}, false);
        TestDescriptor testCase1 = new MyTestDescriptor("MyTestClass", new String[] {"nesting", "myTest"}, true);

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet1));
        listener.executionStarted(TestIdentifier.from(testSet2));
        listener.executionStarted(TestIdentifier.from(testCase1));
        listener.executionFinished(TestIdentifier.from(testCase1), TestExecutionResult.successful());
        listener.executionFinished(TestIdentifier.from(testSet2), TestExecutionResult.successful());
        listener.executionFinished(TestIdentifier.from(testSet1), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(1, 1, 0);
    }

    @Test
    void abortedTest() {
        TestOutputReportEntryTestReportListener testReportListener = new TestOutputReportEntryTestReportListener();
        TestDescriptor testSet = new MyTestDescriptor("MyTestClass");
        TestDescriptor testCase = new MyTestDescriptor("MyTestClass", "myTest");

        TestExecutionListener listener = new TestExecutionListener(testReportListener);
        listener.executionStarted(TestIdentifier.from(testSet));
        listener.executionStarted(TestIdentifier.from(testCase));
        listener.executionFinished(TestIdentifier.from(testCase), TestExecutionResult.aborted(null));
        listener.executionFinished(TestIdentifier.from(testSet), TestExecutionResult.successful());

        testReportListener.assertTestSets(1, 1);
        testReportListener.assertTests(1, 0, 0, 0, 0, 1);
    }

    private static class TestOutputReportEntryTestReportListener implements TestReportListener<TestOutputReportEntry> {
        List<TestSetReportEntry> startingTestSets = new ArrayList<>();
        List<TestSetReportEntry> completedTestSets = new ArrayList<>();
        List<ReportEntry> startingTests = new ArrayList<>();
        List<ReportEntry> successfulTests = new ArrayList<>();
        List<ReportEntry> assumptionFailures = new ArrayList<>();
        List<ReportEntry> failedTests = new ArrayList<>();
        List<ReportEntry> skippedTests = new ArrayList<>();
        List<ReportEntry> erroredTests = new ArrayList<>();

        @Override
        public boolean isDebugEnabled() {
            return false;
        }

        @Override
        public void debug(String s) {

        }

        @Override
        public boolean isInfoEnabled() {
            return false;
        }

        @Override
        public void info(String s) {

        }

        @Override
        public boolean isWarnEnabled() {
            return false;
        }

        @Override
        public void warning(String s) {

        }

        @Override
        public boolean isErrorEnabled() {
            return false;
        }

        @Override
        public void error(String s) {

        }

        @Override
        public void error(String s, Throwable throwable) {

        }

        @Override
        public void error(Throwable throwable) {

        }

        @Override
        public void testSetStarting(TestSetReportEntry report) {
            startingTestSets.add(report);
        }

        @Override
        public void testSetCompleted(TestSetReportEntry report) {
            completedTestSets.add(report);
        }

        @Override
        public void testStarting(ReportEntry report) {
            startingTests.add(report);
        }

        @Override
        public void testSucceeded(ReportEntry report) {
            successfulTests.add(report);
        }

        @Override
        public void testAssumptionFailure(ReportEntry report) {
            assumptionFailures.add(report);
        }

        @Override
        public void testError(ReportEntry report) {
            erroredTests.add(report);
        }

        @Override
        public void testFailed(ReportEntry report) {
            failedTests.add(report);
        }

        @Override
        public void testSkipped(ReportEntry report) {
            skippedTests.add(report);
        }

        @Override
        public void testExecutionSkippedByUser() {

        }

        @Override
        public void writeTestOutput(TestOutputReportEntry reportEntry) {

        }

        public void assertTestSets(int starting, int completed) {
            assertEquals(starting, startingTestSets.size(), "starting test sets");
            assertEquals(completed, completedTestSets.size(), "completed test sets");
        }

        public void assertTests(int starting, int successful, int failed) {
            assertTests(starting, successful, failed, 0, 0);
        }

        public void assertTests(int starting, int successful, int failed, int errored, int skipped) {
            assertTests(starting, successful, failed, errored, skipped, 0);
        }

        public void assertTests(int starting, int successful, int failed, int errored, int skipped, int aborted) {
            assertEquals(starting, startingTests.size(), "starting tests");
            assertEquals(successful, successfulTests.size(), "successful tests");
            assertEquals(failed, failedTests.size(), "failed tests");
            assertEquals(errored, erroredTests.size(), "errored tests");
            assertEquals(skipped, skippedTests.size(), "skipped tests");
            assertEquals(aborted, assumptionFailures.size(), "assumptions failed");
        }
    }

    private static class MyTestDescriptor implements TestDescriptor {
        private final String testClass;
        private final Type type;
        private final UniqueId uniqueId;
        private final TestSource source;

        public MyTestDescriptor(String testClass) {
            this.testClass = testClass;
            this.type = Type.CONTAINER;
            this.uniqueId = UniqueId.forEngine("jupiter").append("class", testClass);
            this.source = ClassSource.from(testClass);
        }

        public MyTestDescriptor(String testClass, String testMethod) {
            this.testClass = testClass;
            this.type = Type.TEST;
            this.uniqueId = UniqueId.forEngine("jupiter").append("class", testClass).append("method", testMethod);
            this.source = MethodSource.from(testClass, testMethod);
        }

        public MyTestDescriptor(String testClass, String[] testMethods, boolean isTest) {
            this.testClass = testClass;
            this.type = isTest ? Type.TEST : Type.CONTAINER;
            UniqueId uniqueId = UniqueId.forEngine("jupiter").append("class", testClass);
            for (String testMethod : testMethods) {
                uniqueId = uniqueId.append("method", testMethod);
            }
            this.uniqueId = uniqueId;
            this.source = ClassSource.from(testClass);
        }

        @Override
        public UniqueId getUniqueId() {
            return uniqueId;
        }

        @Override
        public String getDisplayName() {
            return testClass;
        }

        @Override
        public Set<TestTag> getTags() {
            return Collections.emptySet();
        }

        @Override
        public Optional<TestSource> getSource() {
            return Optional.of(source);
        }

        @Override
        public Optional<TestDescriptor> getParent() {
            return Optional.empty();
        }

        @Override
        public void setParent(TestDescriptor parent) {

        }

        @Override
        public Set<? extends TestDescriptor> getChildren() {
            return Collections.emptySet();
        }

        @Override
        public void addChild(TestDescriptor descriptor) {

        }

        @Override
        public void removeChild(TestDescriptor descriptor) {

        }

        @Override
        public void removeFromHierarchy() {

        }

        @Override
        public Type getType() {
            return type;
        }

        @Override
        public Optional<? extends TestDescriptor> findByUniqueId(UniqueId uniqueId) {
            return Optional.empty();
        }
    }
}
