Sitecore Parameter driven publish deployment tool
=================================================

On automatically deployment or scripted Sitecore releases you would properly also do a scripted publish. Or maybe just publish to the one that is removed from the load balancer and wait until the publish is finished. With this publish module you can do that, just give your wishes in the url querystring parameters to the module. With a second script IsPublishTaskRunning.aspx you can poll and see when the publish is done.

##Installation instructions
place the ParameterDrivenPublish.aspx and IsPublishTaskRunning.aspx into the \sitecore\admin folder on your Sitecore CMS installation.


##Running
Go the /sitecore/admin/ParameterDrivenPublish.aspx
Find the correct querystring parameter and add the url to your continuous integration or continuous delivery system. The page show all the available web databases and lets you choose between full or smart publish.

For the Is Publish running check go to:
/sitecore/admin/IsPublishTaskRunning.aspx
 
##Note:
The pages do not have a login be sure you don’t deploy it to a accessible server without protected the admin urls. maybe you can remove the tool after use.
Every access to the script will logged in the Sitecore Log.
