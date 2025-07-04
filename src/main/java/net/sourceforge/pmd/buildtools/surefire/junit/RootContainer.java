/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools.surefire.junit;

import org.junit.platform.engine.UniqueId;
import org.junit.platform.launcher.TestIdentifier;

class RootContainer {
    private final TestIdentifier testIdentifier;
    private boolean hasTests = false;

    RootContainer(TestIdentifier testIdentifier) {
        this.testIdentifier = testIdentifier;
    }

    public boolean isIdentifier(TestIdentifier testIdentifier) {
        return this.testIdentifier.equals(testIdentifier);
    }

    public void markHasAtLeastOneTest() {
        hasTests = true;
    }

    public boolean hasNoTests() {
        return !testIdentifier.getUniqueIdObject().hasPrefix(UniqueId.forEngine("junit-platform-suite"))
            && !hasTests;
    }
}
