/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools;

import net.sourceforge.pmd.testframework.SimpleAggregatorTst;

public class DoNotUseJavaUtilLoggingTest extends SimpleAggregatorTst {
    @Override
    public void setUp() {
        addRule("net/sourceforge/pmd/pmd7-dogfood-config.xml", "DoNotUseJavaUtilLogging");
    }
}
