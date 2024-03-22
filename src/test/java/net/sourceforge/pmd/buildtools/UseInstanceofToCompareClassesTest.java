/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools;

import net.sourceforge.pmd.test.SimpleAggregatorTst;

class UseInstanceofToCompareClassesTest extends SimpleAggregatorTst {
    @Override
    protected void setUp() {
        addRule("net/sourceforge/pmd/pmd-dogfood-config.xml", "UseInstanceofToCompareClasses");
    }
}
