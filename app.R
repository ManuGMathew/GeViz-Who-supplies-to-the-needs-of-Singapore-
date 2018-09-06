
#Import Packages
# The for loop import Code not Working when deployed in Shiny" Comment the lines below and 
# uncomment those library calls below that to publish.

packages = c('shiny','shinydashboard', 'tidyverse', 'plotly',
             'shinythemes', 'DT', 'tm', 'lda',
             'LDAvis', 'devtools', 'servr', 'treemap',
             'd3treeR', 'lettercase', 'visNetwork', 'tidygraph',
             'lubridate', 'ggplot2', 'scales', 'zoo',
             'quantmod', 'ggthemes','data.tree', 'dygraphs')

if(!require(d3treeR)){
    devtools::install_github("timelyportfolio/d3treeR")
}

if(!require(data.tree)){
    devtools::install_github("gluc/data.tree")
}

for (package in packages){
    if(!require(package, character.only = T)){
        install.packages(package)
    }
    library(package, character.only = T)
}


# library(shiny)
# library(tidyverse)
# library(plotly)
# library(shinythemes)
# library(DT)
# library(tm)
# library(lda)
# library(LDAvis)
# library(servr)
# library(treemap)
# library(d3treeR)
# library(lettercase)
# library(visNetwork)
# library(tidygraph)
# library(lubridate)
# library(ggplot2)
# library(scales)
# library(zoo)
# library(quantmod)
# library(ggthemes)
# library(data.tree)
# library(dygraphs)

# Read in the Data
input_df = read_csv("data/government-procurement-via-gebiz.csv")
min_df = read_csv("data/Ministry Reference.csv")

#Global Variables ----

#Derived Dataframes
input_df_new = data.frame()
unfulfilled_orders = data.frame()
#node = data.frame()

#Data Preparation ----
input_df_original = input_df

# Join both the data
input_df = left_join(input_df, min_df, by = c("agency"))

#Data Prep Function
data_prep = function(input_df){
    
    #Convert the data into right type.
    # procurement_data = procurement_data %>% 
    #     mutate(
    #         agency = as.factor(agency),
    #         tender_detail_status = as.factor(tender_detail_status),
    #         supplier_name = as.factor(supplier_name),
    #         ministry = as.factor(ministry)
    #         )
    
    #Convert Supplier Names to Uniform format.
    input_df$supplier_name = str_cap_words(str_lower(input_df$supplier_name))
    
    ##Recode possible duplicates
    input_df$ministry = recode(
        input_df$ministry,
        "Ministry of Law (MinLaw)" = "Ministry of Law (MINLAW)"
    )
    
    #Optional - To reduce length of Label
    input_df$ministry_abbr = recode(
        input_df$ministry,
        "Ministry of Finance (MOF)" = "MOF",
        "Organs of State" = "ORGSTATE",
        "Ministry of National Development (MND)" = "MND",
        "Ministry of Transport (MOT)" = "MOT",
        "Ministry of Trade and Industry (MTI)" = "MTI",
        "Ministry of Culture, Community and Youth (MCCY)" = "MCCY",
        "Ministry of Social and Family Development (MSF)" = "MSF",
        "Ministry of Education (MOE)"  = "MOE",
        "Ministry of Manpower (MOM)" = "MOM",
        "Ministry of Home Affairs (MHA)" ="MHA",
        "Prime Minister's Office (PMO)" = "PMO",
        "Ministry of Defence (MINDEF)" = "MINDEF",
        "Ministry of the Environment and Water Resources (MEWR)" = "MEWR",
        "Ministry of Foreign Affairs (MFA)" = "MFA",
        "Ministry of Health (MOH)" = "MOH",
        "Ministry of Information, Communications and the Arts (MICA)" = "MICA",
        "Ministry of Law (MINLAW)" = "MINLAW"
    )
    
    ministry_names = c("Ministry of Finance",
                       "Organs of State",
                       "Ministry of National Development",
                       "Ministry of Transport",
                       "Ministry of Trade and Industry",
                       "Ministry of Culture, Community and Youth",
                       "Ministry of Social and Family Development",
                       "Ministry of Education",
                       "Ministry of Manpower",
                       "Ministry of Home Affairs",
                       "Prime Minister's Office",
                       "Ministry of Defence",
                       "Ministry of the Environment and Water Resources",
                       "Ministry of Foreign Affairs",
                       "Ministry of Health",
                       "Ministry of Information, Communications and the Arts",
                       "Ministry of Law"
    )
    
    ministry_abbr_list = c(
        "MOF",
        "ORGSTATE",
        "MND",
        "MOT",
        "MTI",
        "MCCY",
        "MSF",
        "MOE",
        "MOM",
        "MHA",
        "PMO",
        "MINDEF",
        "MEWR",
        "MFA",
        "MOH",
        "MICA",
        "MINLAW"
    )
    
    for(i in c(1:length(ministry_names))){
        input_df$agency = gsub(ministry_names[i],ministry_abbr_list[i],input_df$agency)
    }
    
    unfulfilled_orders <<- input_df %>% 
        filter(tender_detail_status == "Awarded to No Suppliers")
    
    input_df = input_df %>% 
        filter(tender_detail_status != "Awarded to No Suppliers")
    
    input_df$tenderType = input_df$awarded_amt
    
    input_df = input_df %>%
        mutate(tenderType=replace(tenderType, awarded_amt <= 6000, "Small Value Purchases"),
               tenderType=replace(tenderType, awarded_amt > 6000 & awarded_amt <= 70000, "Quotations"),
               tenderType=replace(tenderType, awarded_amt > 70000, "Tender"))
    
    
    return(input_df)
}

input_df = data_prep(input_df)

#-----------------------------------------------------Global Variables------------------------------#

#-----------------------------------------------------Visualization Specific Functions------------------------------#
#Sankey Chart

#Define function for coloring
mapToColor <- function(vector, vector2 = vector, palette = c("#D0D0FF", "#8080FF"), n=128){
    colorRampPaletteFunc <- colorRampPalette(palette)
    min_val <- min(c(vector, vector2))
    max_val <- max(c(vector, vector2))
    portion_vector <- (vector - min_val) / (max_val - min_val)
    index_vector <- ceiling(portion_vector * n)
    index_vector[index_vector == 0] <- 1 ## force 0 (mininum value of the vector) to 1 
    out <- colorRampPaletteFunc(n)[index_vector]
    return(out)
}

sankey_wrapper <- function(
    input2_df, topic_chosen = "", agency_chosen = "", ministry_chosen = "", 
    n_ministry = 20, n_agency = 30, n_supplier = 50, n_agency_per_ministry = 3, 
    n_supplier_per_agency = 5, node_pad = 10, label_font_size = 13, 
    value_based = FALSE, title = ""){
    
    layer_df <- data.frame("source_var" = c("ministry", "agency"), 
                           "target_var" = c("agency", "supplier_name"), 
                           "n_source" = c(n_ministry, n_agency), 
                           "n_target" = c(n_agency, n_supplier), 
                           "n_target_per_source" = c(n_agency_per_ministry, n_supplier_per_agency),
                           stringsAsFactors = FALSE)
    
    node_df <- data.frame()
    edge_df <- data.frame()
    
    sub_df <- input2_df
    
    if ((topic_chosen != "") ){
        sub_df  <- sub_df  %>% 
            mutate_(topic_flag = topic_chosen) %>% 
            filter(topic_flag == TRUE)
    }
    
    if ((agency_chosen != "") & (!is.na(agency_chosen)) ){
        sub_df  <- sub_df  %>% 
            filter(agency == agency_chosen)
    }
    
    if ((ministry_chosen != "") & (!is.na(ministry_chosen))){
        sub_df  <- sub_df  %>% 
            filter(ministry == ministry_chosen)
    }
    
    
    if ((ministry_chosen == "") & (agency_chosen == "")){n_loops <- 1}
    else{n_loops <- 2}
    
    for (i in 1:n_loops) {
        
        source_var <- layer_df$source_var[[i]] 
        target_var <- layer_df$target_var[[i]] 
        n_source <- layer_df$n_source[[i]]
        n_target <- layer_df$n_target[[i]]
        n_target_per_source <- layer_df$n_target_per_source[[i]]
        
        df <- sub_df %>% 
            mutate_(source_label = source_var) %>% 
            mutate_(target_label = target_var)
        
        ### edge ###
        
        sum_df <- df
        
        if(i == 1) {
            sum_target_label_df <- data.frame()
        } else {
            sum_df <- sum_df %>% 
                semi_join(sum_target_label_df %>% 
                              rename(source_label = label), by = "source_label")
        } 
        
        sum_df <- sum_df %>% 
            group_by(source_label, target_label) %>% 
            summarize(count=n(), value=sum(awarded_amt)) %>%
            ungroup()
        
        if(value_based){
            sum_df <- sum_df  %>%
                group_by(source_label) %>%
                top_n(n_target_per_source, value) %>%
                ungroup()
        }
        else{
            sum_df <- sum_df  %>%
                group_by(source_label) %>%
                top_n(n_target_per_source, count) %>%
                ungroup()
        }
        
        edge_df <- edge_df %>% rbind(sum_df)
        
        
        if(i==1){
            ### source node ###
            sum_source_label_df <- sum_df %>% 
                rename(label = source_label) %>% 
                group_by(label) %>% 
                summarize(count=sum(count), value=sum(value)) %>%
                ungroup() 
            
            if(value_based){
                sum_source_label_df <- sum_source_label_df %>% 
                    top_n(n_source, value)
            }
            else {
                sum_source_label_df <- sum_source_label_df %>% 
                    top_n(n_source, count)
            }
            
            node_df <- node_df %>% rbind(sum_source_label_df)
            
        }
        
        ### target node ###
        sum_target_label_df <- sum_df %>% 
            rename(label = target_label) %>% 
            group_by(label) %>% 
            summarize(count=sum(count), value=sum(value)) %>%
            ungroup()
        
        if(value_based){
            sum_target_label_df <- sum_target_label_df %>% 
                top_n(n_target, value)
        } 
        else{
            sum_target_label_df <- sum_target_label_df %>% 
                top_n(n_target, count)
        }
        
        node_df <- node_df %>% rbind(sum_target_label_df)
    }
    
    node_df <- node_df %>% 
        na.omit() %>%
        unique() %>%
        mutate(index = row_number() - 1)
    
    edge_df <- edge_df %>% 
        inner_join((node_df %>% rename(source_label = label) %>% rename(source = index)), by = "source_label") %>% 
        inner_join((node_df %>% rename(target_label = label) %>% rename(target = index)), by = "target_label")
    
    
    ### Apply log10 function to the value because the procurement from Singapore Sports Council to Axxel Marketing Pte Ltd is dominant
    #edge_df$value <- log10(edge_df$value)
    
    ### Visualize by Sankey diagram
    p <- plot_ly(
        type = "sankey",
        orientation = "h",
        #orientation = "v",
        arrangement = "fixed",
        valuesuffix = if(value_based){" (SG$)"} else{" counts"},
        valueformat = ",d",
        node = list(
            label = node_df$label,
            color = if(value_based){mapToColor(node_df$count, edge_df$count, c("#E1F5FE", "#0277BD"))} else{mapToColor(node_df$value, edge_df$value)}, 
            pad = node_pad,
            thickness = 30,
            line = list(
                color = "black",
                width = 1
                #iterations = 0
            )
        ),
        
        link = list(
            source = edge_df$source,
            target = edge_df$target,
            color = if(value_based){mapToColor(edge_df$count, node_df$count, c("#E1F5FE", "#0277BD"))} else{mapToColor(edge_df$value, node_df$value)},
            value = if(value_based){edge_df$value} else{edge_df$count}
        )
    ) %>% 
        layout(
            title = title,
            font = list(
                size = label_font_size
            ),
            titlefont = list(size = 13)
        )
    
    p
}

#Time series Plot (Stacked Chart to show procurement breakdown)
plot_ts = function(input_df, filter_ministry = "", filter_agency = "", filter_supplier = ""){
    
    if(is.null(filter_ministry) | filter_ministry %in% c("","All")){
        filter_ministry = unique(input_df$ministry)
    }
    if(is.null(filter_agency) | filter_agency %in% c("","All")){
        filter_agency = unique(input_df$agency)
    }
    if(is.null(filter_supplier) | filter_supplier %in% c("","All")){
        filter_supplier = unique(input_df$supplier_name)
    }
    
    timeseries = input_df %>%
        mutate(yearmon = as.yearmon(award_date)) %>%
        filter(ministry %in% filter_ministry & agency %in% filter_agency & supplier_name %in% filter_supplier) %>%
        group_by(yearmon,tenderType) %>%
        summarise(count = n()) %>%
        spread(key = tenderType,value = count) %>%
        ungroup() %>%
        mutate(yearmon = as.Date(yearmon)) 
    
    timeseries2 = xts(timeseries[,2:4], order.by = timeseries$yearmon)
    
    dygraph(timeseries2, main = "Monthly Procurements Breakdown (Stacked Graph)") %>%
        dyHighlight(highlightSeriesOpts = list(strokeWidth = 3)) %>%
        dyRangeSelector(strokeColor = "darkblue", fillColor = "darkblue") %>%
        dyOptions(colors = c("darkblue", "darkgrey", "darkred"),
                  stackedGraph = TRUE,
                  drawGrid = FALSE)%>%
        dyAxis("y", label = "Number of Procurements")
    
}

# Calender Plot Function
calender_process = function(input_df, filter_ministry = "", filter_agency = "", filter_supplier = ""){
    
    if(is.null(filter_ministry) | filter_ministry %in% c("","All")){
        filter_ministry = unique(input_df$ministry)
    }
    if(is.null(filter_agency) | filter_agency %in% c("","All")){
        filter_agency = unique(input_df$agency)
    }
    if(is.null(filter_supplier) | filter_supplier %in% c("","All")){
        filter_supplier = unique(input_df$supplier_name)
    }
    
    input_df$award_date = ymd(input_df$award_date)
    
    input_df$year=as.numeric(as.POSIXlt(input_df$award_date)$year+1900)
    # the month too 
    input_df$month=as.numeric(as.POSIXlt(input_df$award_date)$mon+1)
    # but turn months into ordered facors to control the appearance/ordering in the presentation
    input_df$monthf=factor(input_df$month,levels=as.character(1:12),labels=c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"),ordered=TRUE)
    # the day of week is again easily found
    input_df$weekday = as.POSIXlt(input_df$award_date)$wday
    # again turn into factors to control appearance/abbreviation and ordering
    # I use the reverse function rev here to order the week top down in the graph
    # you can cut it out to reverse week order
    input_df$weekdayf=factor(input_df$weekday,levels=rev(0:6),labels=rev(c("Mon","Tue","Wed","Thu","Fri","Sat","Sun")),ordered=TRUE)
    # the monthweek part is a bit trickier 
    # first a factor which cuts the data into month chunks
    input_df$yearmonth=as.yearmon(input_df$award_date)
    input_df$yearmonthf=factor(input_df$yearmonth)
    # then find the "week of year" for each day
    input_df$week = as.numeric(format(input_df$award_date,"%W"))
    # and now for each monthblock we normalize the week to start at 1 
    input_df = input_df %>%
        group_by(yearmonthf)%>%
        mutate(monthweek = 1+week-min(week)) %>%
        ungroup()
    
    calender = input_df %>%
        filter(supplier_name!="na") %>%
        filter(ministry %in% filter_ministry & agency %in% filter_agency & supplier_name %in% filter_supplier) %>%
        group_by(monthweek,weekdayf,year,monthf) %>%
        summarise(Counts = n())
    
    return (calender)
}


# Viznetwork Function
graph_process = function(input_df, filter_ministry = "", filter_agency = "", filter_supplier = ""){
    
    
    if(is.null(filter_ministry) | filter_ministry == "" ){
        filter_ministry = unique(input_df$ministry)
    }
    if(is.null(filter_agency) | filter_agency %in% c("","All")){
        filter_agency = unique(input_df$agency)
    }
    if(is.null(filter_supplier) | filter_supplier %in% c("","All")){
        filter_supplier = unique(input_df$supplier_name)
    }
    
    ministry_df = input_df %>%
        filter(supplier_name!="na") %>%
        filter(ministry %in% filter_ministry & agency %in% filter_agency & supplier_name %in% filter_supplier) %>%
        distinct(ministry) %>%
        rename(label = ministry) %>%
        mutate(group = "Ministry")
    
    agencies_df = input_df %>%
        filter(supplier_name!="na") %>%
        filter(ministry %in% filter_ministry & agency %in% filter_agency & supplier_name %in% filter_supplier) %>%
        distinct(agency)%>%
        rename(label = agency)%>%
        mutate(group = "Agency")
    
    suppliers_df = input_df %>%
        filter(supplier_name!="na") %>%
        filter(ministry %in% filter_ministry & agency %in%filter_agency & supplier_name %in% filter_supplier) %>%
        distinct(supplier_name)%>%
        rename(label = supplier_name) %>%
        mutate(group = "Supplier")
    
    consol =  bind_rows(ministry_df, agencies_df, suppliers_df)
    
    node = consol %>%
        mutate(id = row_number()) %>%
        select(id,label,group)
    
    edge_agencytosupplier = input_df %>%
        filter(supplier_name!="na") %>%
        filter(ministry %in% filter_ministry & agency %in% filter_agency & supplier_name %in% filter_supplier) %>%
        left_join(node, by = c("agency" = "label")) %>%
        rename(from = id)%>%
        left_join(node, by = c("supplier_name" = "label")) %>%
        rename(to = id) %>%
        group_by(from, to) %>%
        summarise(value = n()) %>%
        filter(from!=to) %>%
        filter(value >= 1) %>%
        ungroup()
    
    edge_ministrytoagency = input_df %>%
        filter(supplier_name!="na") %>%
        filter(ministry %in% filter_ministry & agency %in%filter_agency & supplier_name %in% filter_supplier) %>%
        left_join(node, by = c("ministry" = "label")) %>%
        rename(from = id)%>%
        left_join(node, by = c("agency" = "label")) %>%
        rename(to = id) %>%
        group_by(from, to) %>%
        summarise(value = n()) %>%
        filter(from!=to) %>%
        filter(value >= 1) %>%
        ungroup()
    
    edge =  bind_rows(edge_agencytosupplier, edge_ministrytoagency)
    return (list(node,edge))  
}

# Calculate closeness 
graph_metrics = function(input_df, filter_ministry = "", filter_agency = "", filter_supplier = ""){
    df = graph_process(input_df, filter_ministry, filter_agency, filter_supplier)
    node = df[[1]]
    edge = df[[2]] %>% 
        mutate(source=from,target=to)
    
    dfgraph <- tbl_graph(nodes = node, edges = edge, directed = TRUE)
    
    g = dfgraph %>%
        mutate(betweenness_centrality = centrality_betweenness()) 
    
    extract = g %>% activate(edges)
    edge = as_tibble(extract)
    extract = g %>% activate(nodes)
    node = as_tibble(extract)
    return (list(node,edge)) 
}

#Setting global node and edge to extract slider range for network graph
components = graph_metrics(input_df,"","","")
node = components[[1]]
edge = components[[2]]

#----------------------------------------------Reactive Blocks--------------------------------------------------#

#-----------------------------------------------------R Shiny Code--------------------------------------------------#

#UI for the application ----
ui <- fluidPage(
    theme = shinytheme("flatly"),
    titlePanel(
        title = h1("GeViz: Who supplies to the needs of Singapore?"),
        windowTitle = "GeViz: Who supplies to the needs of Singapore?"
    ),
    navbarPage(
        "",
        id = "navBar",
        tabPanel(
            "1.0 Overview",
            value = "1.0_Overview",
            tabsetPanel(
                tabPanel(
                    "1.1 About the Project",
                    fluidRow(column(6,htmlOutput("1.1_About_Project")))
                )
            )
        ),
        tabPanel(
            "2.0 Import Data",
            tabsetPanel(
                id = "2.0_Import_Data",
                tabPanel(
                    "2.1 Select Data for Analysis",
                    sidebarLayout(
                        sidebarPanel(
                            # Input: Select Data Source 
                            radioButtons("data_source_option", 
                                         "Select Preferred Data Source",
                                         choices = c("Default Data Source" = 'default',
                                                     "New Data Source" = 'new_data'
                                         ),
                                         selected = 'default'),
                            conditionalPanel(
                                "input.data_source_option == 'new_data'",
                                fileInput("file1", "Choose CSV File",
                                          multiple = TRUE,
                                          accept = c("text/csv",
                                                     "text/comma-separated-values,text/plain",
                                                     ".csv")),
                                # Horizontal line 
                                tags$hr(),
                                
                                # Input: Checkbox if file has header 
                                checkboxInput("header", "Header", TRUE),
                                
                                # Input: Select separator 
                                radioButtons("sep", "Separator",
                                             choices = c(Comma = ",",
                                                         Semicolon = ";",
                                                         Tab = "\t"),
                                             selected = ","),
                                
                                # Input: Select quotes 
                                radioButtons("quote", "Quote",
                                             choices = c(None = "",
                                                         "Double Quote" = '"',
                                                         "Single Quote" = "'"),
                                             selected = '"'),
                                actionButton(
                                    inputId = "2.1_replaceDefault",
                                    label = "Overwrite Default Data"
                                ),
                                conditionalPanel(
                                    "input.2.1_replaceDefault == 0",
                                    textOutput("text_2.1_replaceDefault")
                                )
                            ),
                            # Horizontal line 
                            tags$hr(),
                            actionButton(
                                inputId = "2.1_proceed", 
                                label = "Next"
                            ),
                            width = 2
                            
                        ),
                        # Main panel for displaying outputs 
                        mainPanel(
                            textOutput("Debug_text"),
                            # Output: Data file ----
                            DTOutput("2.1_contents")
                        )
                    )
                ),
                tabPanel(
                    "2.2 Validate Data",
                    value = "2.2_Validate_Ministry_References",
                    sidebarLayout(
                        sidebarPanel(
                            actionButton(
                                inputId = "2.2_proceed", 
                                label = "Proceed to Visualizations"
                            ),
                            width = 2
                        ),
                        mainPanel(
                            textOutput("2.2_info"),
                            DTOutput("2.2_contents")
                        )
                    )
                    
                )
            )
        ),
        tabPanel(
            "3.0 Data Visualization",
            value = "3.0_Data_Visualization",
            tabsetPanel(
                id = "3.0_Data_Visualization",
                tabPanel(
                    "3.1 Procurement Expenses",
                    value = "3.1_Cash_Flow",
                    # Add a sidebar layout to the application
                    sidebarLayout(
                        # Add a sidebar panel around the text and inputs
                        sidebarPanel(
                            width = 2,
                            # Input: Select separator for treemap
                            radioButtons("treemapType", 
                                         "Select a Treemap View",
                                         choices = c("Color based on Ministry" = 'view1',
                                                     "Color based on Agency" = 'view2'
                                         ),
                                         selected = 'view1')
                        ),
                        # Add a main panel around the plot
                        mainPanel(
                            h3("Amount Spent by Different Ministries"),
                            tags$hr(),
                            uiOutput("plot_3.1.1"),
                            actionButton("show", "Show Ministry to Abbrevation Mapping"),
                            h3("Procurements at Individual Ministry Level"),
                            tags$hr(),
                            fluidRow(
                                column(
                                    5,
                                    # Input: Select value for sankey
                                    radioButtons("sankey_view", 
                                                 "Toggle View",
                                                 choices = c("Top N Agency Supplier" = 'top_n',
                                                             "Specific Ministry Agency" = 'min_agency'
                                                 ),
                                                 selected = 'top_n')
                                ),
                                column(
                                    5,
                                    # Input: Select value for sankey
                                    radioButtons("sankey_value", 
                                                 "Select value to Display",
                                                 choices = c("Expense Amount" = 'currency',
                                                             "Number of Procurements" = 'count'
                                                 ),
                                                 selected = 'currency')
                                )
                            ),
                            uiOutput("plot_3.1.2_selector"),
                            plotlyOutput("plot_3.1.2")
                        )
                    )
                ),
                tabPanel(
                    "3.2 Ministry and Suppliers",
                    mainPanel(
                        h3("Count of Transactions by Type of Tender"),
                        plotlyOutput("plot_3.2.1"), 
                        h3("Distribution of Tender Amount by Ministry"),
                        plotlyOutput("plot_3.2.2")
                    )
                ),
                tabPanel(
                    "3.3 Order Patterns",
                    sidebarLayout(
                        sidebarPanel(
                            selectInput("plot_3.3_ministry",
                                        label = "Select a Ministry", 
                                        choices = c("All",unique(input_df$ministry)),
                                        selected = "All", #unique(input_df$ministry),
                                        multiple = TRUE),
                            htmlOutput("plot_3.3_agency_selector"),
                            htmlOutput("plot_3.3_supplier_selector")
                        ),                               
                        mainPanel(
                            h3("Number of Procurements over the Years"),
                            plotOutput("plot_3.3_calenderchart"),
                            h3("Number of Procurements by Type of Tender"),
                            dygraphOutput("plot_3.3_stackedchart")
                        )
                    )
                ),
                tabPanel(
                    "3.4 Topic Modelling",
                    #h3("Generate a new Topic Model"),
                    #sliderInput("nTerms", "Number of terms to display", min = 20, max = 40, value = 30),
                    h3("Generate topic Model"),
                    h3("Topic Model Visualization"),
                    radioButtons("topic_model_option", 
                                 "Select Topic Model to Visualize",
                                 choices = c("Previously Saved Model" = "default",
                                             "Current Data" = "new_data"
                                 ),
                                 selected = "default"),
                    conditionalPanel(
                        "input.topic_model_option == 'new_data'",
                        htmlOutput('tm_delay')
                        ),
                    tags$hr(),
                    visOutput('myChart')
                )
            )
            
        ),
        tabPanel(
            "4.0 Association Visualization",
            tabsetPanel(
                tabPanel(
                    "4.1 Overview",
                    sidebarLayout(
                        sidebarPanel(
                            selectInput("plot_4.1_ministry",
                                        label = "Select a Ministry", 
                                        choices = unique(input_df$ministry),
                                        selected = unique(input_df$ministry)[1]),
                            width = 3,
                            htmlOutput("plot_4.1_agency_selector"),
                            htmlOutput("plot_4.1_supplier_selector"),
                            htmlOutput("plot_4.1_betweenness_selector")
                        ),                               
                        mainPanel(
                            h3("Network at Ministry Level"),
                            tags$hr(),
                            visNetworkOutput("filterednetwork", width = "100%", height = "600px"),
                            DTOutput("nodetable")
                        )
                    )
                    # fluidRow(
                    #     column(5,
                    #            selectInput("plot_4.1_ministry",
                    #                        label = "Select a Ministry", 
                    #                        choices = unique(input_df$ministry),
                    #                        selected = unique(input_df$ministry)[1],
                    #                        multiple = TRUE)
                    #     ),
                    #     column(3,
                    #            htmlOutput("plot_4.1_agency_selector")
                    #     ),
                    #     column(3,
                    #            htmlOutput("plot_4.1_supplier_selector")
                    #     )
                    # ),
                    # visNetworkOutput("filterednetwork",width = "100%", height = "600px")
                ),
                tabPanel(
                    "4.2 Supplier Networks",
                    sidebarLayout(
                        sidebarPanel(
                            selectInput("plot_4.2_supplier",
                                        label = "Select a Supplier", 
                                        choices = unique(input_df$supplier_name),
                                        selected = unique(input_df$supplier_name)[1],
                                        multiple = TRUE),
                            width = 3
                        ),                               
                        mainPanel(
                            visNetworkOutput("suppliernetwork",width = "100%", height = "600px"),
                            DTOutput("nodetable_supplier")
                        )
                    )
                )
            )
        ),
        tabPanel(
            "5.0 View and Export Data",
            sidebarLayout(
                sidebarPanel(
                    actionButton(
                        inputId = "5.0_export",
                        label = "Export Data"
                    ),
                    conditionalPanel(
                        "input.5.0_export == 0",
                        textOutput("text_5.0_export")
                    ),
                    width = 2
                ),
                mainPanel(
                    h3("Active Data"),
                    DTOutput("table")
                )
            )
        )
        
    )
    
)

# server logic ----
server <- function(input, output, session){
    
    #1.0 Overview
    
    output$'1.1_About_Project' = renderUI(
        tagList(
            tags$p(
                "GeBIZ is a government-to-business public eProcurement business centre where 
                suppliers can conduct electronic commerce with the Singapore Government. Due to 
                the vast number of quotations & tenders each year, it becomes extremely challenging to 
                track transactional patterns and entities who are involved in each of these contracts. 
                Some of the issues that might have arisen includes:"
            ),
            tags$ul(
                tags$li(
                    "Tedious for potential supplier to research past tenders, 
                quotations and period contracts of similar purchases across the entire public 
                sector to determine quotation prices "), 
                tags$li("Lack of Ministry oversight on how the budgets were spent in the individual 
                    sectors and service categories"), 
                tags$li("Inability to identify reliable suppliers that many agencies and their 
                    respective ministries are purchasing from"),
                tags$li("Recommend appropriate procurement categories and suggest possible suppliers to 
                    invite during the tender notification process ")
            ),
            tags$p("With the provision of GeBIZ procurement data, current analysis is limited to Agencies and 
               Supplies and we will not be able to view the interactions across ministries. Furthermore, 
               information on the type of contracts were also embedded in long text descriptions which makes 
               it difficult to analyse how have budgets been spent."),
            tags$p("In view of current constraints, we are motivated to create a dynamic and interactive 
               dashboard to help provide ministries, agencies and suppliers a holistic view on the procurement contracts made thus far. ")
        )
        
    )
    #2.0 Import Data
    
    #2.1
    output$'2.1_contents' <- renderDT({
        
        #input$'2.1_proceed'
        # input$file1 will be NULL initially. After the user selects
        # and uploads a file, all rows will be shown.
        if(input$data_source_option == 'new_data')
        {
            req(input$file1)
            
            input_df_new <<- read_delim(input$file1$datapath,
                                        delim = input$sep,
                                        col_names = input$header,
                                        quote = input$quote
            )
            
            input_df_original <<- input_df
            
            input_df <<- input_df_new
            
            input_df_temp = input_df
            
            # Join the data with the ministry reference
            input_df <<- left_join(input_df, min_df, by = c("agency"))
            input_df <<- data_prep(input_df)
            
        }
        
        if(input$data_source_option == 'default'){
            
            input_df <<- input_df_original 
            input_df_temp = input_df
            
            # Join the data with the ministry reference
            input_df <<- left_join(input_df, min_df, by = c("agency"))
            input_df <<- data_prep(input_df)
            
            
        }
        
        return(datatable(input_df_temp,style = 'bootstrap'))
        
    })
    
    observeEvent(input$'2.1_proceed', {
        updateTabsetPanel(session = session, inputId = "2.0_Import_Data", selected = "2.2_Validate_Ministry_References")
        
    })
    
    observeEvent(input$'2.1_replaceDefault',{
        output$text_2.1_replaceDefault = renderText({
            input$'2.1_replaceDefault'
            
            req(input$file1)
            
            tryCatch(
                {
                    write_csv(input_df_new,"data/government-procurement-via-gebiz.csv")
                    return("Default data overwritten successfully.")
                },
                error=function(cond){
                    return("Data Overwrite failed")
                }
            )
            
        })
    })
    
    #2.2
    output$'2.2_info' = renderText({
        
        "The below table shows the entries with Agencies unable to be matched with ministries."
    })
    
    #To output records with unmatched Ministry and Agency
    output$'2.2_contents' <- renderDT({
        
        missing_references = input_df %>% filter(is.na(ministry))
        
        return(datatable(missing_references,style = 'bootstrap'))
    })
    
    
    #To move to Data Visualization Page
    observeEvent(input$'2.2_proceed',{
        updateTabsetPanel(session = session, inputId = "navBar", selected = "3.0_Data_Visualization")
    })
    
    #3.0
    output$"plot_3.1.1" = renderUI({
        if(input$treemapType == 'view1'){
            return(d3tree2Output("plot_3.1.1_v1"))
        }
        else
        {
            return(d3tree3Output("plot_3.1.1_v2"))
        }
    })
    
    output$'plot_3.1.1_v1' = renderD3tree2({
        sum_df <- input_df %>% 
            group_by(ministry_abbr, agency) %>%
            summarize(num_orders=n(), amount=sum(awarded_amt)/1000000)%>%
            ungroup()
        sum_df$agency = gsub("[&]","and",sum_df$agency)
        
        
        inter = d3tree2(
            treemap(
                sum_df,
                index = c("ministry_abbr","agency"),
                vSize = "num_orders",
                vColor = "amount",
                type = "value",
                title = "Government Structure",
                palette ="PuBu"
            ),
            rootname = "Government"
        )
        
        return(inter)
    })
    
    output$'plot_3.1.1_v2' = renderD3tree3({
        sum_df <- input_df %>% 
            group_by(ministry_abbr, agency) %>%
            summarize(num_orders=n(), amount=sum(awarded_amt)/1000000)%>%
            ungroup()
        sum_df$agency = gsub("[&]","and",sum_df$agency)
        
        
        inter = d3tree3(
            treemap(
                sum_df,
                index = c("ministry_abbr","agency"),
                vSize = "num_orders",
                vColor = "amount",
                type = "value",
                title = "Government Structure",
                palette ="PuBu"
            ),
            rootname = "Government"
        )
        
        return(inter)
    })
    
    output$'table_3.1.1' = renderTable({
        #Add code for DT display here
        sub_df = input_df %>% 
            distinct(ministry_abbr, ministry) %>%
            rename("Ministry" = "ministry", "Abbreviation" = "ministry_abbr")
        return(sub_df)
    })
    
    observeEvent(input$show, {
        showModal(modalDialog(
            title = "Ministry to Abbrevation Mapping",
            tableOutput('table_3.1.1'),
            easyClose = TRUE
        ))
    })
    
    output$"plot_3.1.2_selector" = renderUI({
        if(input$sankey_view == 'top_n'){
            tagList(
                fluidRow(
                    column(5,
                           selectInput("plot_3.1_ministry",
                                       label = "Select a Ministry", 
                                       choices = unique(input_df$ministry),
                                       selected = unique(input_df$ministry)[1])
                           #uiOutput("plot_3.1.2_input")
                    ),
                    column(3,
                           numericInput("plot_3.1_num_agencies", 
                                        "Number of Agencies to show", 
                                        value = 3, 
                                        min = 1, 
                                        max = 10)
                    ),
                    column(3,
                           numericInput("plot_3.1_num_suppliers", 
                                        "Number of Suppliers to show", 
                                        value = 3, 
                                        min = 1, 
                                        max = 10)
                    )
                )
            )    
        } else {
            tagList(   
                fluidRow(
                    column(5,
                           selectInput("plot_3.1_ministry",
                                       label = "Select a Ministry", 
                                       choices = unique(input_df$ministry),
                                       selected = unique(input_df$ministry)[1])
                           #uiOutput("plot_3.1.2_input")
                    ),
                    column(5,
                           uiOutput("plot_3.1.2_agency_selector")
                    )
                )
            )    
        }
    })
    
    output$plot_3.1.2_agency_selector = renderUI({
        
        req(input$plot_3.1_ministry)
        
        sub_df = input_df %>% filter(ministry %in% as.list(input$plot_3.1_ministry))
        
        selectInput("plot_3.1.2_agency",
                    label = "Select Agency", 
                    choices = unique(sub_df$agency),
                    selected = unique(sub_df$agency)[1]
        )
    })
    
    output$plot_3.1.2 <- renderPlotly({
        #Add code for Plot here
        req(input$sankey_value, input$sankey_view)
        
        if(input$sankey_value == 'currency')
        {
            by_value = TRUE
            
        }else if(input$sankey_value == 'count'){
            by_value = FALSE
        }
        
        if(input$sankey_view == 'top_n'){
            req(input$plot_3.1_ministry, input$plot_3.1_num_agencies, input$plot_3.1_num_suppliers
            )
            
            print(paste(input$plot_3.1_ministry,
                        as.character(input$plot_3.1_num_agencies),
                        as.character(input$plot_3.1_num_suppliers))
            )
            
            p = sankey_wrapper(input_df, 
                               ministry_chosen = input$plot_3.1_ministry, 
                               n_agency_per_ministry = input$plot_3.1_num_agencies,
                               n_supplier_per_agency = input$plot_3.1_num_suppliers, 
                               value_based = by_value,
                               title = paste("Cash flow from",input$plot_3.1_ministry))
            return(p)
            
        }else if(input$sankey_view == 'min_agency'){
            p = sankey_wrapper(input_df, 
                               #topic_chosen = "V2", 
                               agency_chosen = input$plot_3.1.2_agency, 
                               n_agency = 5, 
                               n_supplier = 30, 
                               n_agency_per_ministry = 5, 
                               n_supplier_per_agency = 7, 
                               node_pad = 10, 
                               label_font_size = 13, 
                               value_based = by_value)
            return(p)
        }
        
        
    })
    
    output$plot_3.2.1 <- renderPlotly({
        
        input_df_temp = input_df %>% 
            group_by(ministry_abbr,tenderType) %>% 
            summarise(count = n())
        
        P = ggplotly(
            ggplot(input_df_temp, aes(x = reorder(ministry_abbr, count), fill = tenderType, y = count)) + 
                geom_bar(stat = "identity") +
                xlab("Ministry") +
                ylab("Number of Procurements") +
                coord_flip()+
                scale_fill_manual(name = "Procurement Type", values = c("darkblue", "darkgrey", "darkred"))  
        )
        
        return (P)
    })
    
    output$plot_3.2.2 <- renderPlotly({
        #Add code for Plot here
        
        P<- ggplotly(
            ggplot(data=input_df, aes(y=awarded_amt, x= ministry_abbr, color = tenderType)) + 
                geom_boxplot() + 
                stat_summary(geom="point", fun.y="median", colour = "red", size=1) + 
                #geom_point(position="jitter", size=0.1, alpha=0.1, color="blue") + 
                xlab("Ministry") +
                ylab("Procurement Amount") +
                coord_flip() +
                scale_color_manual(name = "Procurement Type", values = c("darkblue", "darkgrey", "darkred"))
        )
        return (P)
    })
    
    output$plot_3.3_agency_selector = renderUI({
        
        req(input$plot_3.3_ministry)
        
        sub_df = input_df %>% 
            filter(ministry %in% as.list(input$plot_3.3_ministry))
        
        selectInput("plot_3.3_agency",
                    label = "Select Agency", 
                    choices = c("All",unique(sub_df$agency)),
                    multiple = TRUE,
                    selected = "All"
        )
    })
    
    output$plot_3.3_supplier_selector = renderUI({
        
        req(input$plot_3.3_ministry, input$plot_3.3_agency)
        
        if(is.null(input$plot_3.3_agency) | input$plot_3.3_agency %in% c("","All")){
            
            sub_agency_df = input_df %>% filter(ministry %in% as.list(input$plot_3.3_ministry))
            filter_agency = unique(sub_agency_df$agency)
            
        }else{
            filter_agency = input$plot_3.3_agency
        }
        
        sub_df = input_df %>% filter(ministry %in% as.list(input$plot_3.3_ministry),
                                     agency %in% as.list(filter_agency))
        
        selectInput("plot_3.3_supplier",
                    label = "Select a Supplier", 
                    choices = c("All",unique(sub_df$supplier_name)),
                    multiple = TRUE,
                    selected = "All")
    })
    
    output$plot_3.3_calenderchart <- renderPlot({
        #Add code for Plot here
        req(input$plot_3.3_ministry, input$plot_3.3_agency, input$plot_3.3_supplier)
        
        calender_df = calender_process(input_df, input$plot_3.3_ministry, input$plot_3.3_agency, input$plot_3.3_supplier)
        
        P = ggplot(calender_df, aes(monthweek, weekdayf, fill = Counts)) + 
            geom_tile(colour = "grey50") + 
            facet_grid(year~monthf) + 
            ggtitle("Number of Procurements Across Time") +  
            xlab("Week of Month") +
            ylab("Weekday") +
            theme_hc() +
            scale_colour_hc()
        
        return(P)
    })
    
    #3.3 time series stacked chart
    output$plot_3.3_stackedchart <- renderDygraph({
        
        req(input$plot_3.3_ministry, input$plot_3.3_agency, input$plot_3.3_supplier)
        
        P = plot_ts(input_df, input$plot_3.3_ministry, input$plot_3.3_agency, input$plot_3.3_supplier)
        
        return(P)
    })
    
    #3.4
    descriptions = reactive({
        
        reviews = input_df$tender_description
        
        stop_words <- c(stopwords("SMART"), "provision", "tender", "year", "years")
        
        # pre-processing:
        reviews <- gsub("'", "", reviews)  # remove apostrophes
        reviews <- gsub("[[:punct:]]", " ", reviews)  # replace punctuation with space
        reviews <- gsub("[[:cntrl:]]", " ", reviews)  # replace control characters with space
        reviews <- gsub('[[:digit:]]+', " ", reviews)
        reviews <- gsub("^[[:space:]]+", "", reviews) # remove whitespace at beginning of documents
        reviews <- gsub("[[:space:]]+$", "", reviews) # remove whitespace at end of documents
        reviews <- tolower(reviews)  # force to lowercase
        
        # tokenize on space and output as a list:
        doc.list <- strsplit(reviews, "[[:space:]]+")
        
        # compute the table of terms:
        term.table <- table(unlist(doc.list))
        term.table <- sort(term.table, decreasing = TRUE)
        
        # remove terms that are stop words or occur fewer than 5 times:
        del <- names(term.table) %in% stop_words | term.table < 5
        term.table <- term.table[!del]
        vocab <- names(term.table)
        
        # now put the documents into the format required by the lda package:
        get.terms <- function(x) {
            index <- match(x, vocab)
            index <- index[!is.na(index)]
            rbind(as.integer(index - 1), as.integer(rep(1, length(index))))
        }
        
        documents <- lapply(doc.list, get.terms)
        
        # Compute some statistics related to the data set:
        D <- length(documents)  # number of documents (2,000)
        W <- length(vocab)  # number of terms in the vocab (14,568)
        doc.length <- sapply(documents, function(x) sum(x[2, ]))  # number of tokens per document [312, 288, 170, 436, 291, ...]
        N <- sum(doc.length)  # total number of tokens in the data (546,827)
        term.frequency <- as.integer(term.table)  # frequencies of terms in the corpus [8939, 5544, 2411, 2410, 2143, ...]
        alpha <- 0.02
        eta <- 0.02
        
        if(input$topic_model_option == "default"){
            fit = readRDS("data/Saved/defaultLdaFit")
        }
        else
        {
            K <- 5
            G <- 5000
            
            fit = lda.collapsed.gibbs.sampler(documents = documents, K = K, vocab = vocab, 
                                        num.iterations = G, alpha = alpha, 
                                        eta = eta, initial = NULL, burnin = 0,
                                        compute.log.likelihood = TRUE)
        }        
        
        theta <- t(apply(fit$document_sums + alpha, 2, function(x) x/sum(x)))
        phi <- t(apply(t(fit$topics) + eta, 2, function(x) x/sum(x)))
        
        descriptions <- list(phi = phi,
                             theta = theta,
                             doc.length = doc.length,
                             vocab = vocab,
                             term.frequency = term.frequency)
        
        document_flags_df <- as.data.frame(t(fit$document_sums) > 0)
        
        input_df <<- cbind(input_df, document_flags_df)
        
        return(descriptions)
    })

    output$myChart <- renderVis({
        description = descriptions()
        
        json <- createJSON(phi = description$phi, 
                           theta = description$theta, 
                           doc.length = description$doc.length, 
                           vocab = description$vocab, 
                           term.frequency = description$term.frequency)
        

        return(json)
        
    })
    
    output$tm_delay = renderUI(
        h5("Please wait while we prepare the model. Expected duration 5-7 minutes")
        
    )
    
    #4.0
    
    #4.1
    output$plot_4.1_agency_selector = renderUI({
        
        req(input$plot_4.1_ministry)
        
        sub_df = input_df %>% filter(ministry %in% input$plot_4.1_ministry)
        
        selectInput("plot_4.1_agency",
                    label = "Select Agency", 
                    choices = c("All",unique(sub_df$agency)),
                    multiple = TRUE,
                    selected = "All"
        )
    })
    
    output$plot_4.1_supplier_selector = renderUI({
        
        req(input$plot_4.1_ministry, input$plot_4.1_agency)
        
        if(is.null(input$plot_4.1_agency) | input$plot_4.1_agency %in% c("","All")){
            
            sub_agency_df = input_df %>% filter(ministry %in% as.list(input$plot_4.1_ministry))
            filter_agency = unique(sub_agency_df$agency)
            
        }else{
            filter_agency = input$plot_4.1_agency
        }
        
        sub_df = input_df %>% filter(ministry %in% as.list(input$plot_4.1_ministry)&
                                         agency %in% as.list(filter_agency))
        
        selectInput("plot_4.1_supplier",
                    label = "Select a Supplier", 
                    choices = c("All",unique(sub_df$supplier_name)),
                    multiple = TRUE,
                    selected = "All")
    })
    
    output$plot_4.1_betweenness_selector = renderUI({
        
        sliderInput("plot_4.1_betweenness", 
                    label = "Select Betweenness", 
                    min = min(node$betweenness_centrality), 
                    max = max(node$betweenness_centrality), 
                    value = c(min(node$betweenness_centrality),max(node$betweenness_centrality)))
    })
    
    
    output$filterednetwork = renderVisNetwork({
        
        req(input$plot_4.1_ministry,input$plot_4.1_agency, input$plot_4.1_supplier)
        
        components = graph_metrics(input_df, input$plot_4.1_ministry, input$plot_4.1_agency, input$plot_4.1_supplier)
        node_local = components[[1]]
        edge_local = components[[2]]
        
        nodefilter = node_local %>% 
            filter(between(betweenness_centrality,input$"plot_4.1_betweenness"[1],input$"plot_4.1_betweenness"[2]))
        edgefilter = edge_local %>% 
            filter(from %in% nodefilter$id | to %in% nodefilter$id)
        
        nw_df = visNetwork(node_local, edgefilter) %>%
            visIgraphLayout(layout = "layout_nicely", randomSeed = 123)%>%
            visEdges(arrows = "to", smooth = list(enabled = TRUE)) %>%
            visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE, selectedBy = "group")%>% 
            visInteraction(navigationButtons = TRUE)%>% 
            visLegend(width = 0.1, position = "right", main = "Group")
        
        ############ extract the table information based on filtered network graph ############
        output_df = input_df %>% filter(ministry %in% nodefilter$label | agency %in% nodefilter$label | supplier_name %in% nodefilter$label)
        
        output$nodetable <- renderDT({
            #Add code for DT display here
            datatable(
                output_df,
                style = 'bootstrap'
            )
        })
        
        return(nw_df)
    })
    
    output$suppliernetwork = renderVisNetwork({
        
        req(input$plot_4.2_supplier)
        
        components = graph_process(input_df, filter_supplier = input$plot_4.2_supplier)
        
        node = components[[1]]
        edge = components[[2]]
        
        nw_df = visNetwork(node, edge) %>%
            visIgraphLayout(layout = "layout_nicely")%>%
            visEdges(arrows = "to", smooth = list(enabled = TRUE)) %>%
            visOptions(highlightNearest = TRUE, nodesIdSelection = TRUE, selectedBy = "group")%>% 
            visInteraction(navigationButtons = TRUE)%>% 
            visLegend(width = 0.1, position = "right", main = "Group")
        
        ############ extract the table information based on filtered network graph ############
        output_df = input_df %>% filter(ministry %in% node$label | agency %in% node$label | supplier_name %in% node$label)
        
        output$nodetable_supplier <- renderDT({
            #Add code for DT display here
            datatable(
                output_df,
                style = 'bootstrap'
            )
        })
        
        return(nw_df)
    })
    #5.0
    output$table <- renderDT({
        #Add code for DT display here
        datatable(
            input_df,
            style = 'bootstrap'
        )
    })
    
    observeEvent(input$'5.0_export',{
        output$text_5.0_export = renderText({
            input$'5.0_export'
            
            tryCatch(
                {
                    write_csv(input_df,"data/Saved/government-procurement-via-gebiz_export.csv")
                    return("Data exported to 'data/Saved/government-procurement-via-gebiz_export.csv'")
                },
                error=function(cond){
                    return("Data Export failed")
                }
            )
            
        })
    })
    
    output$loadingText = renderText("Preparing Visualizations")
    
}

# Run the application 
shinyApp(ui = ui, server = server)





