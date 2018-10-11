
<div class=WordSection1>

<p class=MsoNormal><b>Abstract</b><span style='color:black'>—</span> <span
lang=EN-GB>Launched in 2000, the Government Electronic Business (GeBIZ) Portal
is an integrated portal for use by all Singapore government agencies to conduct
business electronically with their suppliers. There are more than S$10 billion
worth of business opportunities published annually to 30,000 suppliers
registered with GeBIZ. Over the years, GeBIZ has accumulated a knowledge base
of procurement data and massive amounts of data is a valuable source of market
knowledge. A Business Intelligence (BI) platform was introduced in 2007 to help
mine this information to help improve the efficiency and effectiveness of
government procurement. </span></p>

<p class=MsoNormal><span lang=EN-GB>However, like any tool it does have its
advantages and disadvantages. As such, we will be exploring ways to help
improve current tools and increase the ability to garner insights. Predominantly,
we will be exploring network graphs (vizNetwork &amp; tidygraph) using a R
shiny application to help visualise the relationships between the Ministries,
Agencies and Suppliers. This will be an additional feature which many off-the
shelf commercial BI tools are still lacking which could serve beneficial.</span></p>

<p class=MsoNormal><b>Index Terms</b><span style='color:black'>—</span> <span
lang=EN-GB>GeBIZ, Procurement, Business
Intelligence, Network Graphs, visNetwork, tidygraph, R Shiny. </span></p>

</div>
<br>

<h1>Motivation of the application</h1>
<span style='font-size:9.0pt;font-family:"Times",serif'>
</span>

<div class=WordSection5>

<p class=BodyNoIndent><span lang=EN-GB>Due to the vast number of quotations
&amp; tenders each year, it becomes extremely challenging to track
transactional patterns and entities who are involved in each of these
contracts. Some of the issues that might have arisen includes: &#8203;</span></p>

<p class=BodyNoIndent style='margin-left:18.0pt;text-indent:-18.0pt'><span
lang=EN-GB style='font-family:Symbol'>·<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-GB>Tedious for potential supplier to research past
tenders, quotations and period contracts of similar purchases across the entire
public sector to determine quotation prices </span></p>

<p class=BodyNoIndent style='margin-left:18.0pt;text-indent:-18.0pt'><span
lang=EN-GB style='font-family:Symbol'>·<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-GB>Lack of Ministry oversight on how the budgets
were spent in the individual sectors and service categories</span></p>

<p class=BodyNoIndent style='margin-left:18.0pt;text-indent:-18.0pt'><span
lang=EN-GB style='font-family:Symbol'>·<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-GB>Inability to identify reliable suppliers&#8203;
that many agencies and their respective ministries are purchasing from</span></p>

<p class=BodyNoIndent style='margin-left:18.0pt;text-indent:-18.0pt'><span
lang=EN-GB style='font-family:Symbol'>·<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-GB>Recommend appropriate procurement categories and
suggest possible suppliers to invite during the tender notification process </span></p>

<p class=BodyNoIndent>
With the provision of GeBIZ procurement data, current analysis is limited to Agencies
and Supplies and we will not be able to view the interactions across
ministries. Furthermore, information on the type of contracts were also embedded
in long text descriptions which makes it difficult to analyse how have budgets
been spent. &#8203;</span></p>

<p class=BodyNoIndent><span lang=EN-GB>In view of current constraints, we are
motivated to create a dynamic and interactive dashboard to help provide
ministries, agencies and suppliers a holistic view on the procurement contracts
made thus far. &#8203;</span></p><br>

<h1>Review and critic on past works</h1>

<p class=MsoNormal><span lang=EN-GB>The development of Business Intelligence in
GeBIZ started in early 2006. GeBIZ BI initiatives can be broadly divided into
two areas. The first area entails the development of GeBIZ InSIGHT. It
leverages on Machine Learning (ML) techniques to help individual procurement
users research historical buys and gain market insights.</span></p>

<p class=MsoNormal><span lang=EN-GB>The second area covers the development of
GeBIZ Management Console (GMC). GMC enables macro-level portfolio management
and performance management in the public sector by its features such as
filtering, pivot tables, and charts. As mentioned, the existing tools</span>
could help gain market insights but there are still ways to help improve how we
analyse information with the use of visual analytical techniques. [2]</p>
<br>

<h1>Design Framework</h1>
<p class=Body>
<span lang=EN-GB>The overview of our approach can be seen in the following
figure.</span></p>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/5/5e/G17_Fig01.png" width="500px">
</span></p>

<p class=BodyNoIndent><span lang=EN-GB>Prior data pre-processing will be
carried out to add in the ministry that these agencies belong to. In addition,
we will segment the contracts based on their dollar value and topic modelling
will also be implemented to determine their respective procurement categories. </span></p>

<p class=BodyNoIndent><span lang=EN-GB>With a three–pronged approach, we will help
explore how the procurement expenses look like across ministries, agencies and
suppliers. We will also investigate if there are seasonal patterns and purchase
types specific to an entity. Lastly, we will leverage on the use of network
graphs to help us understand their relationships and extract their procurement
information at ease with an interactive interface.</span></p>
<br>

<h2>Network Visualization</h2>

<p class=Body>
  <span lang=EN-GB>
    <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/a/a6/G17_Fig02.png/750px-G17_Fig02.png" width="500px">
  </span>
</p>

<p class=MsoNormal><b><i>visNetwork</i></b> was chosen as our preferred library
to visualize network relations as it fosters interactivity which a user will be
able to appreciate when dealing with complex nodes and edges. However, due to
the lack of functions to implement centrality metrices like betweenness, we
have made use of <b><i>tidygraph</i></b> to help us with the implementation and
extraction of these additional columns. </p>

<p class=MsoNormal><span lang=EN-US>In graph
theory,&nbsp;betweenness&nbsp;centrality [9] is a measure of centrality in a
graph based on shortest paths.</span> A node with high betweenness would mean
that it <span lang=EN-US>would have more control over the network, because more
information will pass through </span>it<span lang=EN-US>.</span> With this
metric in the procurement context, we would like to identify key suppliers
which deals across multiple Agencies. </p>

<p class=MsoNormal>The transition from <b><i>tidygraph</i></b> to <b><i>visNetwork</i></b>,
however requires us to manipulate our data before it will be compatible for the
individual libraries. In tidygraph, we need to ensure that the columns are
renamed to “source” and “target” while visNetwork uses “from” and “to”. Using <u>dplyr</u>,
we can easily perform dataframe manipulation.</p>

<p class=MsoNormal>As <u>tidygraph</u> also creates a tbl_graph which contains
two tibble object where we can use a combination of <i>activate</i> and <i>as_tibble</i>
functions to help extract the node and edge table.</p>

<p class=Body>
  <span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/e/e8/G17_Fig03.png/600px-G17_Fig03.png" width="400px">
  </span>
</p>

<p class=MsoNormal>Once we have the relevant information, we can create a
“Group” column and visNetwork will be able to display these groups as distinct
colours. Setting the number of contracts as “value” also help visNetwork plot
edges with difference thickness. The thicker the edge, the more contracts that
are involved between 2 nodes.</p>
<br>

<h2>Treemap</h2>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/0/0a/G17_Fig04.png/750px-G17_Fig04.png" width="500px">
</span></p>

<p class=BodyNoIndent><span lang=EN-GB>Treemap is a powerful way to visualize
hierarchical data using nested rectangles. The advantage is that all data can
be visualized in a single page utilizing rectangle area for the primary
measure, and color for the second measure. Treemaps can be generated by a d3treeR
library (https://github.com/d3treeR/d3treeR) in R. </span></p>

<p class=BodyNoIndent><span lang=EN-GB>While looking at Procurements,
visualizing expenses at the Ministry and Agency level help us identify key
spenders. This is useful when we want to know which ministry and which agency
in that ministry tend to spend more. We use a Treemap Diagram to visualize the
expenses at the ministry Level. The size of the tiles in the Treemap represent
the number of orders placed by the ministry and the color indicates the amount
spent. In the Sankey, we show the spending at ministry level for its top N
agencies and the top N suppliers within each individual agency.</span></p>
<br>

<h2>Sankey Diagram</h2>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/6/69/G17_Fig05.png/750px-G17_Fig05.png" width="500px">
  </span></p>

<p class=BodyNoIndent><span lang=EN-GB>Sankey Diagram is another effective way
to visualize a network graph as flow. The advantage of Sankey Diagram over Sunburst
Diagram and regular network visualization is that nodes (and thus node labels)
and edges are aligned in line, and the primary measure (count of procurement or
monetary value SG$ in our dataset) represented by edge width can be compared
with each other easily. In addition, the second measure can be represented by
the color. Sankey Diagram can be generated by Plotly library
(https://plot.ly/r/sankey-diagram/) in R.</span></p>
<br>

<h2>Latent Dirichlet Allocation</h2>

<p class=MsoNormal>Latent Dirichlet Allocation (LDA) is an example of Topic
Modeling technique that enabled us to extract procurements type information
from text descriptions. LDA assumes each word in each text sample was chosen
from topics which consist of words which have different probabilities to be
chosen. Given the number of topics, LDA determines 2 distributions; distribution
of words for each topic, and distribution of topics for each text sample. LDA
can be run by lda library (https://cran.r-project.org/web/packages/lda/lda.pdf&#8203;)
in R. LDA was used to extract information from the text description column in
our dataset. The output of LDA can be visualized on the plane of principal
component axes by LDAvis library in R.  (https://nlp.stanford.edu/events/illvi2014/papers/sievert-illvi2014.pdf)
</p>
<br>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/b/b1/G17_Fig06.png/750px-G17_Fig06.png" width="500px">
  </span></p>

<p class=MsoNormal>LDA by setting the number of topics to 5 extracted 3 distinct
topics (Topic 2, 3, and 5) on the plane of principal components as shown in the
above screenshots. Based on the interactive visualized results, the 5 topics
were labeled as follows.</p>
<br>

<p class=MsoNormal>Topic 1: Communication (relevant words: invitation,
appointment, proposal, request])</p>

<p class=MsoNormal>Topic 2: Task (relevant words: works, engineering,
consultancy, upgrading, building, road])</p>

<p class=MsoNormal>Topic 3: Product support (relevant words: system,
installation, maintenance, testing)&#8203;</p>

<p class=MsoNormal>Topic 4: General (relevant words: period, term, month,
option)&#8203;</p>

<p class=MsoNormal>Topic 5: Public/Organization (relevant words: school,
boards, state, departments, organs)</p>
<br>

<h2>Time Series </h2>
'''1. Calendar Plot'''
<br>
<img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/7/71/G17_Fig07.png/750px-G17_Fig07.png" width="500px">
<br>

<p class=BodyNoIndent><span lang=EN-GB>The essence to plot a calendar chart
requires us to be able to manipulate data time to the necessary formats before
we can obtain our desired graph. More importantly, string variables needs to be
converted as factors so that weekdays and months could be interpreted as  ordinal
variables. </span></p>

<p class=BodyNoIndent><span lang=EN-GB>Using <b><i>ggplot2</i> </b>with its <b><i>geom_tile</i></b>
function, we can visualise the number of procurements across time in a calendar
chart. This will help us identify if there are seasonality or cyclical patterns
within an agency or supplier. For this example, one of the ministries tend to
procure more during the end of the month. This will be useful for suppliers to
help prepare for these peak bidding cycles. </span></p>

'''2. Stacked Line Chart'''

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/b/b7/G17_Fig08.png/750px-G17_Fig08.png" width="500px">
  </span>
</p>

<br clear=ALL>
The stacked plot was created using the <b><i>dygraph </i></b>library which is a
fast, reliable open source JavaScript charting library. Aggregating the number
of contracts by month using <b><i>dplyr</i></b>, we are able to identify trends
&amp; proportion of contracts contributed by the individual tenders segments. Upon
inspection, a cyclical pattern becomes obvious with a spike in the number of
contracts before April, which coincides with the end of the financial year. 
<br>

<h1> Demonstration </h1>

<p class=Heading1Introduction> </p>

<p class=BodyNoIndent><span lang=EN-GB>Considering the limitations of current Business
Intelligence (BI) tools for GeBiz in place [2], we will place more emphasis on the
use of network graph to help identify the hierarchical relationships amongst
entitles in this section.</span></p>

<h2> Network Overview</h2>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/8/82/G17_Fig09.png/750px-G17_Fig09.png" width="500px">
  </span></p>
<br>

<p class=Body><span lang=EN-GB>Using Ministry of Finance (MOF) as an example,
we will be able to identify its respective Agencies and also their suppliers where
they have individually engaged with thus far. This provides an oversight on who
the <b>budgets</b> were spent on in the individual sectors. </span></p>

<p class=Body><span lang=EN-GB>As the chart is interactive, we will be able to
drag around the nodes and zoom in to uncover who have made the most number of
contracts.</span></p>

<p class=BodyNoIndent><span lang=EN-GB>Here, MOF – Vital have sent out the
greatest number of tenders amongst other agencies from MOF.</span></p>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/3/39/G17_Fig10.png/750px-G17_Fig10.png" width="500px">
  </span></p>
<br>

<p class=Body><span lang=EN-GB>If we are interested to know the details of the
tenders MOF – Vital have made, we can filter based on Agency and view the
details in an interactive data table below. Sorting by awarded date, we will be
able to find out the most recent contracts. </span></p>

<p class=Body><span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/4/49/G17_Fig11.png/750px-G17_Fig11.png|500px" width="500px">
  </span></p>
<br>

<p class=Body><span lang=EN-GB>The inclusion of the search function also allows
us to find out past quotations of similar procurement types. This will help
suppliers research past tenders, quotations and period contracts of similar
purchases across the entire public sector to determine quotation prices. This
will not be made possible without the use of LDA where it has helped us
generate a series of procurement types which a tender could belong to. </span></p>

<p class=Body>
  <span lang=EN-GB>
    <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/0/01/G17_Fig12.png/450px-G17_Fig12.png" width="300px">
  </span>
</p>
<br>

<p class=Body><span lang=EN-GB>This is an additional feature which have been
added compared to the current BI systems where they use Support Vector machines
to predict multi-class labels. Here, LDA provides a probability distribution
across topics for 1 observation. This means that a procurement contract could
be multi-labelled instead. Now, we can suggest possible suppliers to invite
during the tender notification process.</span></p>

<p class=Body>
  <span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/e/e1/G17_Fig13.png/750px-G17_Fig13.png" width="500px">
  </span>
</p>
<br>

<p class=Body><span lang=EN-GB>With the introduction of the betweenness
centrality metric, we will now be able to identify the reliable
suppliers&#8203; that many agencies and their respective ministries are
purchasing from. Using the interactive data table, one will be able uncover
that Aetos Security Management Pte. Ltd helps with the provision of armed
security personnel across government agencies. </span></p>
<br>

<h2>Supplier Analysis</h2>
<p class=Body>
  <span lang=EN-GB>
  <img src="https://wiki.smu.edu.sg/1718t3isss608/img_auth.php/thumb/f/fc/G17_Fig14.png/750px-G17_Fig14.png" width="500px">
  </span>
</p>

<p class=Body><span lang=EN-GB>If we are interested to find out the Agencies
that a particular supplier has previously dealt with, we will also be able to
do so on the Supplier Network tab.  This is essential for Agencies when they
would like to evaluate on potential suppliers for the tenders they have put up.
This also fosters collaboration across government Agencies where they could
garner feedback on these suppliers which aids them in their decisions. </span></p>

<p class=Body><span lang=EN-GB>Similarly, a data table have been included below
which will react to the filters chosen and provide the details of past
contracts if necessary.</span></p>
<br>

<h1>Discussion</h1>
<p class=BodyNoIndent><span lang=EN-GB>We presented our work at the Visual
analytics Conference and Poster Presentation held in Singapore Management
university on 12-Aug 2018. We showcased the various features of our application
and received positive comments on the capability of the Application to bring up
a Network of people associated with various ministries and suppliers.</span></p>

<p class=Body><span lang=EN-GB>Members of the audience were particularly
impressed by the Network Visualization and one of them commented on the layout
of the network visualization which we had, stating that this was one feature he
hasn’t seen in other relevant works using the visNetwork package for network
visualization. Also, many were amazed at the amount of visualizations possible
and the smooth interfacing in R Shiny. The audience kept reaffirming that the
whole application has been done in pure R.</span></p>
<br>

<h1>Future work</h1>
'''1. Fixing the view of vizNetwork'''

<p class=MsoNormal>When the betweenness scale is adjusted, the network graph’s
layout changes and it might be difficult to identify the suppliers who are not
well connected. Using igraph’s layout, we will be able to fix the layout and
adjust the filters in visNetwork. This should make it more intuitive for users
when they interact with the graph</p>

'''2. Enhancement of Supplier Information'''
<p class=BodyNoIndent><span lang=EN-GB>In the dataset, information about
supplier is only the name. It will be beneficial to add supplier information,
such as industry and financial health and performance information such as
revenue, gross profit, net profit, and change of stock price.</span></p>

'''3. Utilize Information Extracted from Text Description'''
<p class=BodyNoIndent><span lang=EN-GB>Utilizing the new columns created based
on LDA which indicates whether each procurement order is related to the topic,
we can filter out the dataset and analyse the pattern in network for each
topic.</span></p>

'''4. Enhance Information Extraction from Text Description'''
<p class=BodyNoIndent><span lang=EN-GB>The dataset includes text description,
and more useful information would be able to be extracted. Tuning of topic
modelling can be done by removing more words that disturb the output and trying
other numbers of topics and the random seed. Other techniques such as Named Entity
Recognition could be helpful as well.</span></p>
<br>

<h1>Acknowledgments</h1>
<p class=Acknowledgements><span lang=EN-GB>The authors greatly thank Dr Tin
Seong KAM for his guidance and suggestions.</span></p>
<br>

<h1>References</h1>
<p class=Reference><span lang=EN-US>[1]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US style='background:white'>GeBIZ. (n.d.).
Retrieved August 8, 2018, from </span><span class=MsoHyperlink><span
lang=EN-US>https://data.gov.sg/dataset?q=GeBIZ</span></span></p>

<p class=Reference><span lang=EN-US>[2]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US>Defence Science &amp; Technology Agency,
“Business Intelligence in Government Procurement – DSTA&quot; (n.d.). Retrieved
August 13, 2018, from <span class=MsoHyperlink>https://www.dsta.gov.sg/docs/default-source/dsta-about/business-intelligence-in-government-procurement.pdf?sfvrsn=2</span></span></p>

<p class=Reference><span lang=EN-US>[3]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US>Programmes - Civil Service College Singapore.
(2018, February 02). Retrieved August 13, 2018, from
https://www.cscollege.gov.sg/Programmes/Pages/Display%20Programme.aspx?ePID=2rblsavgweogwh2qu9lgtunfma</span></p>

<p class=Reference><span lang=EN-US>[4]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US style='background:white'>D3treeR. (2018,
February 06) Retrieved August 8, 2018, from <span class=MsoHyperlink>https://github.com/d3treeR/d3treeR</span></span></p>

<p class=Reference><span lang=EN-US>[5]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US style='background:white'>Sankey Diagram. (n.d.).
Retrieved August 8, 2018, from <span class=MsoHyperlink>https://plot.ly/r/sankey-diagram/</span></span></p>

<p class=Reference><span lang=EN-US>[6]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US style='color:#333333;background:white'>visNetwork
(n.d.). Retrieved August 8, 2018, from </span><span class=MsoHyperlink><span
lang=EN-US style='background:white'>https://datastorm-open.github.io/visNetwork/</span></span></p>

<p class=Reference><span lang=EN-US>[7]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US style='color:#333333;background:white'>CRAN -
Package lda. (n.d.). Retrieved August 8, 2018, from </span><span
class=MsoHyperlink><span lang=EN-US style='background:white'>https://cran.r-project.org/web/packages/lda/</span></span></p>

<p class=Reference><span class=MsoHyperlink><span lang=EN-US style='color:windowtext;
text-decoration:none'>[8]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span></span><span lang=EN-US style='background:white'>LDAvis (2018,
April 25). Retrieved August 8, 2018, from </span><span class=MsoHyperlink><span
lang=EN-US style='color:#333333'>https://github.com/cpsievert/LDAvis</span></span></p>

<p class=Reference><span lang=EN-US>[9]<span style='font:7.0pt "Times New Roman"'>&nbsp;&nbsp;&nbsp;&nbsp;
</span></span><span lang=EN-US>Betweenness Centrality (n.d). Retrieved August
6, 2018 from https://en.wikipedia.org/wiki/Betweenness_centrality</span></p>

<p class=AcknowledgementTitle>&nbsp;</p>

</div>

<b><span style='font-size:9.0pt;font-family:"Helvetica",sans-serif;font-variant:
small-caps;letter-spacing:.65pt'><br clear=all style='page-break-before:auto'>
</span></b>

<div class=WordSection6>

<p class=AcknowledgementTitle>&nbsp;</p>

<b><span style='font-size:9.0pt;font-family:"Helvetica",sans-serif;font-variant:
small-caps;color:#333333;letter-spacing:.65pt'><br clear=all style='page-break-before:
always'>
</span></b>
