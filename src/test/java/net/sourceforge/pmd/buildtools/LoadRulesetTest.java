/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools;

import org.junit.Assert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.contrib.java.lang.system.SystemErrRule;

import net.sourceforge.pmd.RulePriority;
import net.sourceforge.pmd.RuleSet;
import net.sourceforge.pmd.RuleSetLoadException;
import net.sourceforge.pmd.RuleSetLoader;

public class LoadRulesetTest {

    @Rule
    public SystemErrRule systemerr = new SystemErrRule().enableLog();

    @Test
    public void testLoadDogFoodRuleset() throws RuleSetLoadException {
        assertRuleset("net/sourceforge/pmd/pmd-dogfood-config.xml");
    }

    @Test
    public void testLoadUiDogFoodRuleset() throws RuleSetLoadException {
        assertRuleset("net/sourceforge/pmd/pmd-ui-dogfood-config.xml");
    }

    private void assertRuleset(String rulesetName) throws RuleSetLoadException {
        RuleSetLoader ruleSetLoader = new RuleSetLoader()
                .filterAbovePriority(RulePriority.LOW)
                .warnDeprecated(true)
                .enableCompatibility(false);
        RuleSet ruleset = ruleSetLoader.loadFromResource(rulesetName);
        Assert.assertNotNull(ruleset);
        Assert.assertFalse(ruleset.getRules().isEmpty());
        Assert.assertTrue(systemerr.getLog().isEmpty()); // there should be no deprecation warnings...
    }
}
