/*
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.buildtools;


import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import net.sourceforge.pmd.lang.rule.RulePriority;
import net.sourceforge.pmd.lang.rule.RuleSet;
import net.sourceforge.pmd.lang.rule.RuleSetLoader;

import com.github.stefanbirkner.systemlambda.SystemLambda;

class LoadRulesetTest {

    @Test
    void testLoadDogFoodRuleset() throws Exception {
        assertRuleset("net/sourceforge/pmd/pmd-dogfood-config.xml");
    }

    @Test
    void testLoadTestDogFoodRuleset() throws Exception {
        assertRuleset("net/sourceforge/pmd/pmd-test-dogfood-config.xml");
    }

    @Test
    void testLoadUiDogFoodRuleset() throws Exception {
        assertRuleset("net/sourceforge/pmd/pmd-ui-dogfood-config.xml");
    }

    private void assertRuleset(String rulesetName) throws Exception {
        RuleSetLoader ruleSetLoader = new RuleSetLoader()
                .filterAbovePriority(RulePriority.LOW)
                .warnDeprecated(true);
        String syserr = SystemLambda.tapSystemErr(() -> {
            RuleSet ruleset = ruleSetLoader.loadFromResource(rulesetName);
            assertNotNull(ruleset);
            assertFalse(ruleset.getRules().isEmpty());
        });
        assertTrue(syserr.isEmpty()); // there should be no deprecation warnings...
    }
}
