/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;

import org.apache.maven.plugin.surefire.log.api.ConsoleLogger;

class MockedConsoleLogger implements ConsoleLogger {
    private StringBuilder info = new StringBuilder();
    private StringBuilder error = new StringBuilder();

    @Override
    public boolean isDebugEnabled() {
        return false;
    }

    @Override
    public void debug(String message) {

    }

    @Override
    public boolean isInfoEnabled() {
        return false;
    }

    @Override
    public void info(String message) {
        info.append(message).append(System.lineSeparator());
    }

    @Override
    public boolean isWarnEnabled() {
        return false;
    }

    @Override
    public void warning(String message) {

    }

    @Override
    public boolean isErrorEnabled() {
        return false;
    }

    @Override
    public void error(String message) {
        error.append(message).append(System.lineSeparator());
    }

    @Override
    public void error(String message, Throwable t) {

    }

    @Override
    public void error(Throwable t) {

    }

    public void assertInfoContains(String s) {
        assertThat(info.toString(), containsString(s));
    }

    public void assertInfo(String s) {
        assertThat(info.toString(), equalTo(s));
    }

    public void assertError(String s) {
        assertThat(error.toString(), equalTo(s));
    }
}
