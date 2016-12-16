/**
 * BSD-style license; for more info see http://pmd.sourceforge.net/license.html
 */

package net.sourceforge.pmd.ant;

import static org.junit.Assert.assertTrue;

import java.io.File;
import java.net.URL;

import org.apache.commons.io.IOUtils;
import org.junit.Test;

import net.sourceforge.pmd.TestBase;

/**
 * @author rpelisse
 *
 */
public class PmdBuildTaskTest extends TestBase {

    @Test
    public void antTask() throws Exception {
        PmdBuildTask task = new PmdBuildTask();
        task.setRulesDirectory(testDirName + "src/main/resources/rulesets");
        task.setTarget(testDirName + "target");
        task.setSiteXml(testDirName + "src/site/site.pre.xml");
        task.setSiteXmlTarget(testDirName + "src/site/site.xml");
        task.setRuntimeClasspath(new URL[] { new File("target/test-classes").toURI().toURL() });
        task.execute();

        String site = IOUtils.toString(new File(testDirName + "src/site/site.xml").toURI());
        assertTrue(site.contains("<item name=\"Basic\""));
        assertTrue(site.contains("<item name=\"Code Size\""));
        assertTrue(site.indexOf("<item name=\"Basic\"") < site.indexOf("<item name=\"Code Size\""));
    }
}
