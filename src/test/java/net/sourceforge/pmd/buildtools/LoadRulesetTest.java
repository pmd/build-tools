/**
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools;

import org.junit.Assert;
import org.junit.Test;

import net.sourceforge.pmd.RuleSet;
import net.sourceforge.pmd.RuleSetFactory;
import net.sourceforge.pmd.RuleSetNotFoundException;

public class LoadRulesetTest {

    @Test
    public void testLoadDogFoodRuleset() throws RuleSetNotFoundException {
        assertRuleset("net/sourceforge/pmd/pmd-dogfood-config.xml");
    }

    @Test
    public void testLoadUiDogFoodRuleset() throws RuleSetNotFoundException {
        assertRuleset("net/sourceforge/pmd/pmd-ui-dogfood-config.xml");
    }

    private void assertRuleset(String rulesetName) throws RuleSetNotFoundException {
        RuleSetFactory ruleSetFactory = new RuleSetFactory();
        RuleSet ruleset = ruleSetFactory.createRuleSet(rulesetName);
        Assert.assertNotNull(ruleset);
        Assert.assertFalse(ruleset.getRules().isEmpty());
    }
}
