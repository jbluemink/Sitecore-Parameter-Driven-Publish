<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="Sitecore" %>
<%@ Import Namespace="Sitecore.SecurityModel" %>
<%@ Import Namespace="Sitecore.Data.Managers" %>
<%@ Import Namespace="Sitecore.Data" %>
<%@ Import Namespace="Sitecore.Publishing" %>
<%@ Import Namespace="Sitecore.Data.Items" %>
<%@ Import Namespace="Sitecore.Configuration" %>

<%@ Page Language="C#" Debug="true" %>

<%@ Import Namespace="Sitecore.Globalization" %>
<%@ Import Namespace="Sitecore.Diagnostics" %>
<%@ Import Namespace="Sitecore.Data.Proxies" %>


<!--
Have fun,
Jan Bluemink, jan@mirabeau.nl
-->
<html>
<script runat="server" language="C#">
  public string status = "Make a choice, then press submit";
  public void Page_Load(object sender, EventArgs e)
  {
      var refresh = Request["refresh"];
      var publishtargets = Request["publishtarget"];
      var publishItem = Request["items"];
      Log.Info($"Parameter Driven Publish script call: Targets = {publishtargets}; Item = {publishItem}", this);
      Sitecore.Context.SetActiveSite("shell");

      if (!string.IsNullOrEmpty(publishtargets))
      {
          var master = Factory.GetDatabase("master");
          publishform.Visible = false;
          publishresetform.Visible = true;
          var targets = GetTargets(publishtargets);
          var itemToPublish = GetPublishItem(publishItem);

          if (targets.Any())
          {
              var smartpublish = Request["smartpublish"];
              if (string.IsNullOrEmpty(smartpublish))
              {
                  status = "Republish " + publishtargets;
                  using (new SecurityDisabler())
                  {
                      var republishLanguages = LanguageManager.GetLanguages(master).ToArray();

                      if (itemToPublish != null)
                      {
                          var publishOptions = BuildOptions(Client.ContentDatabase, itemToPublish, targets, republishLanguages, PublishMode.Full, true, false, true);
                          PublishManager.Publish(publishOptions);
                      }
                      else
                      {
                          PublishManager.Republish(Client.ContentDatabase, targets, republishLanguages, Sitecore.Context.Language);
                      }
                  }
              }
              else
              {
                  status = "Smart publish " + publishtargets;
                  using (new SecurityDisabler())
                  {
                      var smartPublishLanguages = LanguageManager.GetLanguages(master).ToArray();
                      if (itemToPublish != null)
                      {
                          var publishOptions = BuildOptions(Client.ContentDatabase, itemToPublish, targets, smartPublishLanguages, PublishMode.Smart, true, false, true);
                          PublishManager.Publish(publishOptions);
                      }
                      else
                      {
                          PublishManager.PublishSmart(Client.ContentDatabase, targets, smartPublishLanguages, Sitecore.Context.Language);
                      }
                  }
              }
              Thread.Sleep(4000);
          }

          Log.Info($"Parameter Driven Publish script call completed for: Targets = {publishtargets}; Item = {publishItem}", this);
      }
      if (refresh == "true")
      {
          status = "Refresh Task monitor";
          publishform.Visible = false;
          publishresetform.Visible = true;
      }
  }


  private static PublishOptions[] BuildOptions(Database sourceDatabase, Item rootItem, Database[] targetDatabases, Language[] languages, PublishMode mode, bool deep, bool compareRevisions, bool publishRelatedItems)
  {
      Assert.ArgumentNotNull((object)sourceDatabase, "sourceDatabase");
      Assert.ArgumentNotNull((object)targetDatabases, "targetDatabases");
      Assert.ArgumentNotNull((object)languages, "languages");
      DateTime utcNow = DateTime.UtcNow;
      PublishOptions[] publishOptionsArray = new PublishOptions[targetDatabases.Length * languages.Length];
      int index = 0;
      if (!sourceDatabase.PublishVirtualItems && rootItem != null && rootItem.RuntimeSettings.IsVirtual)
          rootItem = ProxyManager.GetRealItem(rootItem, false);
      foreach (Database targetDatabase in targetDatabases)
      {
          foreach (Language language in languages)
          {
              Language languageWithOrigin = LanguageManager.GetLanguage(language.Name, sourceDatabase);
              publishOptionsArray[index] = new PublishOptions(sourceDatabase, targetDatabase, mode, languageWithOrigin, utcNow, Sitecore.Security.Accounts.User.Current)
              {
                  Deep = deep,
                  CompareRevisions = compareRevisions,
                  PublishRelatedItems = publishRelatedItems
              };
              if (rootItem != null)
                  publishOptionsArray[index].RootItem = rootItem;
              ++index;
          }
      }
      return publishOptionsArray;
  }

  protected string GetTime()
  {
      return DateTime.Now.ToString("t");
  }

  private static Database[] GetTargets(string publishtargets)
  {
      var arrayList = new ArrayList();
      foreach (var name in publishtargets.Split(','))
      {
          if (name.Length > 0)
          {
              var database = Factory.GetDatabase(name, false);
              if (database != null)
                  arrayList.Add((object)database);
              else
                  Log.Warn("Unknown database in PublishAction: " + name, publishtargets);
          }
      }
      return arrayList.ToArray(typeof(Database)) as Database[];
  }

  private static Item GetPublishItem(string publishItem)
  {
      var database = Factory.GetDatabase("master");
      if (string.IsNullOrEmpty(publishItem))
      {

          var rootItemToPublish = database.Items["{11111111-1111-1111-1111-111111111111}"];
          return rootItemToPublish;
      }

      var itemId = HttpUtility.HtmlDecode(publishItem);
      var itemToPublish = database.Items[itemId];
      if (itemToPublish != null)
          return itemToPublish;

      Log.Warn("Unknown item in PublishAction: " + itemId, publishItem);
      return null;

  }


  protected static string GetDatabaseNameHtml()
  {
      var masterDb = Factory.GetDatabase("master");
      var html = "";
      using (new SecurityDisabler())
      {
          var obj = masterDb.Items["/sitecore/system/publishing targets"];
          if (obj != null)
          {
              foreach (BaseItem baseItem in obj.Children)
              {
                  var name = baseItem["Target database"];
                  if (name.Length > 0)
                  {
                      html += "<input type=\"checkbox\" name=\"publishtarget\" value=\"" + name + "\">" + name + "<br>";
                  }
              }
          }
      }
      return html;
  }


  protected static string GetPublishItems()
  {
      var htmlBuilder = new StringBuilder();

      htmlBuilder.Append("<input type=\"radio\" name=\"items\" value=\"{11111111-1111-1111-1111-111111111111}\">Whole Site<br>");
      htmlBuilder.Append("<input type=\"radio\" name=\"items\" value=\"{0DE95AE4-41AB-4D01-9EB0-67441B7C2450}\">Content<br>");
      htmlBuilder.Append("<input type=\"radio\" name=\"items\" value=\"{3D6658D8-A0BF-4E75-B3E2-D050FABCF4E1}\">Media Library<br>");
      htmlBuilder.Append("<input type=\"radio\" name=\"items\" value=\"{3C1715FE-6A13-4FCF-845F-DE308BA9741D}\">Templates<br>");
      htmlBuilder.Append("<input type=\"radio\" name=\"items\" value=\"{EB2E4FFD-2761-4653-B052-26A64D385227}\">Layouts<br>");

      return htmlBuilder.ToString();
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
              wait = false;
          }
      }
      if (wait)
      {
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
                      if (par.GetType() != typeof(PublishStatus)) continue;
                      var ps = (PublishStatus)par;
                      html += $" CurrentLanguage:{(ps.CurrentLanguage == null ? "Onbekend" : ps.CurrentLanguage.ToString())} CurrentTarget:{ps.CurrentTarget}";
                  }
              }
          }
          else if (job.Name.StartsWith("Publish"))
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
    <asp:Panel ID="publishresetform" runat="server" Visible="false">
        <a href="/sitecore/admin/ParameterDrivenPublish.aspx">New Publish</a>
    </asp:Panel>
    <asp:Panel ID="publishform" runat="server" Visible="true">
        <form id="MyForm" method="get">
            Publish targets:
       
            <p>
                <%=GetDatabaseNameHtml() %>
            </p>

            <p>
                <%= GetPublishItems() %>
            </p>


            Settings:
       
            <p>
                <input type="checkbox" name="smartpublish" value="smartpublish">Smartpublish instead of Full Republish<br />
            </p>

            <input type="submit" value="Submit Publish Action"><br />
            <hr>
            Current server time is <% =GetTime()%>
        </form>
    </asp:Panel>
    <p>
        <b>Running Tasks</b><br />
        <%= GetRunningTasks() %>
    </p>
    <a href="/sitecore/admin/ParameterDrivenPublish.aspx?refresh=true">Refresh</a>

</body>
</html>
