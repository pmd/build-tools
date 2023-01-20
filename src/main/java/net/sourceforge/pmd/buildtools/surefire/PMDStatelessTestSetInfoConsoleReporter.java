/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire;

import org.apache.maven.plugin.surefire.extensions.junit5.JUnit5StatelessTestsetInfoReporter;
import org.apache.maven.plugin.surefire.log.api.ConsoleLogger;
import org.apache.maven.plugin.surefire.report.TestSetStats;
import org.apache.maven.plugin.surefire.report.WrappedReportEntry;
import org.apache.maven.surefire.extensions.StatelessTestsetInfoConsoleReportEventListener;

/**
 * <p>This is a test set info reporter extension for maven surefire. Unlike the default reporter, all test sets
 * that belong to the same test class (that includes nested test sets) are accumulated and the summary
 * is reported only once for the test class. This avoids seeing summaries with 0 tests executed,
 * which are test sets that only act as container nodes without tests.</p>
 *
 * <p>It outputs to the console. It uses the default implementations for writing the text report files
 * in target/surefire-reports.</p>
 *
 * <p>It can be configured to list individual test cases as well. This is useful for failed test cases.
 * This is inspired by maven-surefire-junit5-tree-reporter.</p>
 *
 * <p>The names of the individual test cases are defined in a way, that it works also with kotest. Tests
 * from kotest only provide the class as the source but no methods. This reporter will fall back to the
 * alternative user-defined naming (which can be achieved in JUnit5 via @DisplayName). Kotest uses the
 * same, but it contains the full path of the nested test sets as well. This reporter extracts the
 * names accordingly.</p>
 *
 * <p>Configuration in pom.xml:
 * <pre>{@code
 * <plugin>
 *     <groupId>org.apache.maven.plugins</groupId>
 *     <artifactId>maven-surefire-plugin</artifactId>
 *     <version>${surefire.version}</version>
 *     <configuration>
 *         <statelessTestsetInfoReporter implementation="net.sourceforge.pmd.buildtools.surefire.PMDStatelessTestsetInfoConsoleReporter">
 *             <showFailedTests>true</showFailedTests>
 *             <showSuccessfulTests>false</showSuccessfulTests>
 *             <showSkippedTests>true</showSkippedTests>
 *             <usePhrasedFileName>true</usePhrasedFileName>
 *             <usePhrasedClassNameInRunning>true</usePhrasedClassNameInRunning>
 *             <usePhrasedClassNameInTestCaseSummary>true</usePhrasedClassNameInTestCaseSummary>
 *         </statelessTestsetInfoReporter>
 *
 *         <statelessTestsetReporter implementation="org.apache.maven.plugin.surefire.extensions.junit5.JUnit5Xml30StatelessReporter">
 *             <usePhrasedFileName>true</usePhrasedFileName>
 *             <usePhrasedTestSuiteClassName>true</usePhrasedTestSuiteClassName>
 *             <usePhrasedTestCaseClassName>true</usePhrasedTestCaseClassName>
 *             <usePhrasedTestCaseMethodName>true</usePhrasedTestCaseMethodName>
 *         </statelessTestsetReporter>
 *     </configuration>
 * </plugin>
 * }</pre>
 *
 * <p>Example output:
 * <pre>{@code
 * [INFO] --- maven-surefire-plugin:3.0.0-M8:test (default-cli) @ pmd-java ---
 * [INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
 * [INFO]
 * [INFO] -------------------------------------------------------
 * [INFO]  T E S T S
 * [INFO] -------------------------------------------------------
 * [INFO] Running net.sourceforge.pmd.lang.java.ast.ASTPatternTest
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 1.3
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 1.4
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 1.5
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 1.6
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 1.7
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 1.8
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 9
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 10
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 11
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 12
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 13
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 14
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO]     └─ Test patterns only available on JDK16 or higher (including preview)
 * [INFO]         └─ Java 15
 * [INFO]             └─ ✘ [unnamed test case]
 * [INFO] Tests run: 31, Failures: 13, Errors: 0, Skipped: 0, Time elapsed: 2.198 s <<< FAILURE! - in net.sourceforge.pmd.lang.java.ast.ASTPatternTest
 * [INFO] Running net.sourceforge.pmd.lang.java.ast.Java15KotlinTest
 * [INFO] Tests run: 7, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.167 s - in net.sourceforge.pmd.lang.java.ast.Java15KotlinTest
 * [INFO] Running net.sourceforge.pmd.lang.java.ast.JUnit5Test
 * [INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.154 s - in net.sourceforge.pmd.lang.java.ast.JUnit5Test
 * [INFO] Running net.sourceforge.pmd.lang.java.symboltable.MethodNameDeclarationTest
 * [INFO]     └─ ✘ testEquality
 * [INFO] Tests run: 1, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.042 s <<< FAILURE! - in net.sourceforge.pmd.lang.java.symboltable.MethodNameDeclarationTest
 * [INFO]
 * }</pre>
 *
 * @see <a href="https://maven.apache.org/surefire/maven-surefire-plugin/examples/junit-platform.html#surefire-extensions-and-reports-configuration-for-displayname">Surefire Extensions and Reports Configuration for @DisplayName</a>
 * @see <a href="https://github.com/fabriciorby/maven-surefire-junit5-tree-reporter">Maven Surefire JUnit5 TreeView Extension</a>
 */
public class PMDStatelessTestSetInfoConsoleReporter extends JUnit5StatelessTestsetInfoReporter {

    private boolean showSuccessfulTests;

    private boolean showFailedTests;

    private boolean showSkippedTests;

    public boolean isShowSuccessfulTests() {
        return showSuccessfulTests;
    }

    public void setShowSuccessfulTests(boolean showSuccessfulTests) {
        this.showSuccessfulTests = showSuccessfulTests;
    }

    public boolean isShowFailedTests() {
        return showFailedTests;
    }

    public void setShowFailedTests(boolean showFailedTests) {
        this.showFailedTests = showFailedTests;
    }

    public boolean isShowSkippedTests() {
        return showSkippedTests;
    }

    public void setShowSkippedTests(boolean showSkippedTests) {
        this.showSkippedTests = showSkippedTests;
    }

    @Override
    public StatelessTestsetInfoConsoleReportEventListener<WrappedReportEntry, TestSetStats> createListener(
            ConsoleLogger logger) {
        return new AccumulatingConsoleReporter(logger, showSuccessfulTests, showFailedTests, showSkippedTests);
    }
}
