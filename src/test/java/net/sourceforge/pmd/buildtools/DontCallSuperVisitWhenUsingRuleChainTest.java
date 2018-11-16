/**
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools;

import net.sourceforge.pmd.testframework.SimpleAggregatorTst;

public class DontCallSuperVisitWhenUsingRuleChainTest extends SimpleAggregatorTst {
    @Override
    public void setUp() {
        addRule("net/sourceforge/pmd/pmd-dogfood-config.xml", "DontCallSuperVisitWhenUsingRuleChain");
    }
}
