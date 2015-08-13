<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="log4net" %>
<%@ Import Namespace="Sitecore" %>
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
<%@ Page Language="C#" Debug="true" %>
<!--
Have fun,
Jan Bluemink, jan@mirabeau.nl
-->
<HTML>
   <script runat="server" language="C#">
       public string status = "Make a choice, then press submit";
       public void Page_Load(object sender, EventArgs e)
       {
          var refresh = Request["refresh"];
       	  var publishtargets = Request["publishtarget"];
          Sitecore.Diagnostics.Log.Info("Mirabeau Publish script call: "+publishtargets, this);
          Sitecore.Context.SetActiveSite("shell");
          
          if (!string.IsNullOrEmpty(publishtargets))
          {
          	  publishform.Visible = false;
          	  publishresetform.Visible= true;
		  Database[] targets = GetTargets(publishtargets);

		  if (targets.Count() > 0)
		  {
		  	  var smartpublish = Request["smartpublish"];
		  	  if (string.IsNullOrEmpty(smartpublish))
		  	  {
				  status = "Republish " + publishtargets;
				  using (new SecurityDisabler())
				  {
				      DateTime publishDate = DateTime.Now;
				      Sitecore.Data.Database master = Sitecore.Configuration.Factory.GetDatabase("master");
				      PublishManager.Republish(Client.ContentDatabase, targets, LanguageManager.GetLanguages(master).ToArray(), Sitecore.Context.Language);
				  }
			  } else {
				  status = "Smart publish " + publishtargets;
				  using (new SecurityDisabler())
				  {
				      DateTime publishDate = DateTime.Now;
				      Sitecore.Data.Database master = Sitecore.Configuration.Factory.GetDatabase("master");
				      PublishManager.PublishSmart(Client.ContentDatabase, targets, LanguageManager.GetLanguages(master).ToArray(), Sitecore.Context.Language);
				  }
			  }
			Thread.Sleep(4000);
		  }
          }
          if (refresh == "true") {
          	status = "Refresh Task monitor";
          	publishform.Visible = false;
          	publishresetform.Visible= true;
          }
       }

       protected String GetTime()
       {
           return DateTime.Now.ToString("t");
       }
       
       private static Database[] GetTargets(string publishtargets)
       {
       	   ArrayList arrayList = new ArrayList();
	   foreach (var name in publishtargets.Split(','))
	   {
	       if (name.Length > 0)
	       {
		   Database database = Factory.GetDatabase(name, false);
		   if (database != null)
		       arrayList.Add((object)database);
		   else
		       Sitecore.Diagnostics.Log.Warn("Unknown database in PublishAction: " + name, publishtargets);
	       }
	   }
	   return arrayList.ToArray(typeof(Database)) as Database[];
        }
        
        
        protected static string GetDatabaseNameHtml()
        {
	   var masterDb = Sitecore.Configuration.Factory.GetDatabase("master");
	   var html = "";
	   using (new SecurityDisabler())
	   {
	       Item obj = masterDb.Items["/sitecore/system/publishing targets"];
	       if (obj != null)
	       {
		   ArrayList arrayList = new ArrayList();
		   foreach (BaseItem baseItem in obj.Children)
		   {
		       string name = baseItem["Target database"];
		       if (name.Length > 0)
		       {
			   html+="<input type=\"checkbox\" name=\"publishtarget\" value=\"" + name + "\">" + name + "<br>";
		       }
		   }
	       }
	   }
	   return html;
        }
        
        protected static string GetRunningTasks()
        {
            var html = "";
	    var jobs = Sitecore.Jobs.JobManager.GetJobs();
	    var wait = true;
	    foreach (var job in jobs)
	    {
		if (job.Name == "Publish")
		{
			wait=false;
		} 
	    }
	    if (wait) {
	    	Thread.Sleep(1000);
	    	jobs = Sitecore.Jobs.JobManager.GetJobs();
	    }
	    foreach (var job in jobs)
	    {
		html += job.Name;
		if (job.Name == "Publish")
		{
			if (job.Options != null && job.Options.Parameters != null)
			{
			    foreach (var par in job.Options.Parameters)
			    {
				if (par.GetType() == typeof (PublishStatus))
				{
				    var ps = (PublishStatus) par;
				    html += string.Format(" CurrentLanguage:{0} CurrentTarget:{1}",ps.CurrentLanguage == null ? "Onbekend" : ps.CurrentLanguage.ToString() ,ps.CurrentTarget);
				}
			    }
			}
		} else if (job.Name.StartsWith("Publish"))
		{
			html += " Processed=" + job.Status.Processed;
		}
		html += "<br>";
	     }
	     return html;
	}
        
        
        
   </script>
   <body>
   <div>This page can be used to publish the Master database.</div>
   <p>
   	<b>Status:</b> <%= status %>
   </p>
<hr> 
<asp:Panel id="publishresetform" runat="server" visible="false">
<a href="/sitecore/admin/MiraPublish.aspx">New Publish</a>
</asp:Panel> 
<asp:Panel id="publishform" runat="server" visible="true">
      <form id="MyForm" action"" method="get">
      Publish targets:
	<p>
	<%=GetDatabaseNameHtml() %>
	</p>
	Settings:
	<p>
	<input type="checkbox" name="smartpublish" value="smartpublish">Smartpublish instead of Full Republish<br/>
	</p>
	
	<input type="submit" value="Submit Publish Action"><br/>
<hr>
	Current server time is <% =GetTime()%>
      </form>
 </asp:Panel>     
      <p>
      <b>Running Tasks</b><br/>
      <%= GetRunningTasks() %>
      </p>
      <a href="/sitecore/admin/MiraPublish.aspx?refresh=true">Refresh</a>
      
   </body>
</HTML>