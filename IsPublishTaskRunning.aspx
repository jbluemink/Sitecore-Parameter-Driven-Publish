<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore.Data.Engines" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Update" %>
<%@ Import Namespace="Sitecore.Update.Installer" %>
<%@ Import Namespace="Sitecore.Update.Installer.Exceptions" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Publishing" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Configuration" %>
<%@ Import Namespace="System.Threading" %>


<%@ Page Language="C#" Debug="true" %>
<!--
Have fun,
Jan Bluemink, jan@mirabeau.nl
-->
<HTML>
   <script runat="server" language="C#">       
        protected static bool IsPulishRunning()
        {
	    var jobs = Sitecore.Jobs.JobManager.GetJobs();
	    foreach (var job in jobs)
	    {
		if (job.Name == "Publish")
		{
			return true;
		} 
	     }
	     return false;
	}
        
        protected static string PublishStatus()
        {
        	if (!IsPulishRunning())
        	{
        		Thread.Sleep(5000);
        		if (!IsPulishRunning()) {
        			return "<status>FALSE-NO-PUBLISH-TASK</status>";
        		}
        	}
        	return "<status>TRUE-PUBLISH-TASK-RUNNING</status>";
        
        }
        
   </script>
   <body>
      <%= PublishStatus() %>   
   </body>
</HTML>