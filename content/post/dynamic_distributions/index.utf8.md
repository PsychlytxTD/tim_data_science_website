---
title: Dynamic Distributions with R Plotly And Purrrr
author: Timothy Deitz, Clinical Psychologist & Aspiring Data Scientist
date: '2019-09-03'
categories:
  - R
  - plotly
  - purrr
  - ggplot2
tags:
  - plotly
  - purrr
  - functional programming
   - ggplot2
output:
  blogdown::html_page:
    toc: yes
---
<style>
body.blue { background-color:#2b3f60;}
</style>

<body class = "blue">







##Setting the Scene

The task of plotting continuous variables is non-negotiable in any data science project. There can be lots of reasons for this. You may need to ensure that your data is normally distributed (a requirement for certain statistical analyses), or you might need to identify and remove outliers.

When it comes to the visualisation of continuous variables, options are plentiful and include histograms, boxplots, density plots, beeswarm plots (good for big data), violin plots (also good for big data), amongst others.

You can easily find instructions for creating such plots in R using ggplot2 or purrr. For example, below is how you would make an interactive histogram in plotly, using both the `plot_ly()` and `ggplotly()` approaches:



```r
#plot_ly syntax 

plotly::plot_ly(mtcars, x = ~disp) %>% plotly::add_histogram() 
```

preservedbdfd9328610672f



```r
#ggplotly syntax

plot<- ggplot(mtcars, aes(x = disp)) + geom_histogram() 

ggplotly(plot)
```

preserve63ef512535db7102


##Dynamically Create Boxplots 

The problem with this code is that if you had 20 continuous variables, you'd have to repeat it 20 times! No thanks. Leveraging the power of functional programming and plotly, I'll instead write a function that takes all numeric variables in dataset and displays each one using an interactive boxplot!

First, I'll write a `show_all_boxplots()` function that generates a list of boxplots for all numeric variables in any dataset. 

Hold on..before we go any further, I'll clean up the mtcars dataset by adding rownames as an explicit variable.



```r
mtcars$car_name<- rownames(mtcars)
```

Right. Onwards. Below, the `show_all_boxplots()` function takes a data argument and an idenifier (categorical variable) argument, to identify individual points
overlaid on each boxplot.



```r
show_all_boxplots<- function(data, identifier) {

  #Select only numeric data for boxplot creation
  
  numeric_data<- dplyr::select_if(data, is.numeric)

  #Iterate over all numeric variables
  #Iterate over names of these variables (needed for labels)
  
  plot_list<- purrr::map2(numeric_data, names(numeric_data), ~{
    
  #Initialise the plot
  #Make tooltip showing important info
  #Identifying variable (e.g. name) is needed to identify outliers

  plot<- ggplot(numeric_data, aes(x = "", y = .x, 
              text = paste("Identifier:", data[,identifier], "<br>",
                  .y, "value:", .x, "<br>",
                  .y, "mean:", round(mean(.x), 2), "<br>",
                  .y, "sd:", round(sd(.x), 2), "<br>",
                  .y, "N outliers:", 
                   nrow(dplyr::filter(numeric_data, 
                   .x > (mean(.x) + 2 * sd(.x))))

    ))) +

    # make boxplot transparent with alpha = 0
    geom_boxplot(alpha = 0) +

    # If a given point is an outlier, colour it red
    
    geom_jitter(color = ifelse(.x > (mean(.x) + 
         2 * sd(.x)), 'red', 'steelblue'), alpha = 0.3) +

    theme(axis.title.x=element_blank()) + ylab(paste(.y))

    ggplotly(plot, tooltip = "text")


})

 #Due to plotly bug, we need to set opacity of boxplot markers
 #to zero, so that outliers aren't duplicated on the plot.
 #Below, go inside each plot object in the list to do this.
  
for(i in 1:length(plot_list)) {

plot_list[[i]][["x"]][["data"]][1][[1]][["marker"]][["opacity"]]<- 0

  }

  return(plot_list)
}
```


Test the `show_all_boxplots()` function:



```r
boxplot_list_test<- show_all_boxplots(mtcars, identifier = "car_name")

##Pick one plot from the list to show

boxplot_list_test[[1]]
```

preservea09ccccc32f5a394


##Dynamically Create Density Plots 

I'm going to write a similar function for density plots. Density plots, when combined with rug plots,
are a great alternative to histograms, and make it easier to compare continuous distributions. Just as it 
is good practice to experiment with varying binwidths for histograms, we also want to let users try different
Gaussian kernel values with density plots - indicated by the `bw` arugment for `geom_density()`.


```r
show_all_density_plots<- function(data, gaussian_kernel = 2.5) {

  numeric_data<- dplyr::select_if(data, is.numeric)

  plot_list<- purrr::map2(numeric_data, names(numeric_data), ~ {

  #Show the skew and kurtosis of each plot in a tooltip
    
  density_plots<- ggplot(numeric_data, aes(x = .x,
                   text = paste("skew:", round(psych::skew(.x), 2), 
                                "<br>",
                   "kurtosis:", round(psych::kurtosi(.x), 2)))) +
      
      geom_density(fill = 'steelblue', bw = gaussian_kernel,  
                   alpha = 0.7) +
      
      #Add the rug to the bottom of the density plot
    
      geom_rug() + xlab(paste0(.y))

      plotly::ggplotly(density_plots)

})

}
```

Test the `show_all_density_plots()` function:


```r
density_plot_list_test<- show_all_density_plots(mtcars)

##Pick a random plot from the list to show

density_plot_list_test[[1]]
```

preserve84dede3bc5c7e3af

##Dynamically Create Histograms 

And finally, I'll write a `show_all_histograms()` function to visualise the actual counts, and not the density.


```r
show_all_histograms<- function(data) {

  numeric_data<- dplyr::select_if(data, is.numeric)

  plot_list<- purrr::map2(numeric_data, names(numeric_data), ~{


  plot<- ggplot(numeric_data, aes(x = .x)) + geom_histogram() + xlab(paste0(.y)) + ylab(paste0(.y))

  ggplotly(plot)

  })
  
}
```

Test the `show_all_histograms()` function 


```r
histogram_plot_list_test<- show_all_histograms(mtcars)

#Print a random plot from the list 

histogram_plot_list_test[[7]]
```

preserve5b11913f0601f14d

##Putting It All Together: One Function To Rule Them All

The aim now is to combine the three functions above into a mega function that goes through a dataframe, plucks out
all numeric variables, and produces 3 distributions (a boxplot, density plot and histogram) for each one. We also want flexibility in how these distributions are displayed. 

It would be good to be able to have the option of specifying which variables to show (if not all) — and to present them in a way that is easily comparable. 

To do this, I write the `show_distributions()` function- hopefully the comments make the steps easier to follow: 


```r
# The `vars_to_show` argument lets the user only show a 
#selection of variables if desired


show_distributions<- function(data, identifier, gaussian_kernel = 2.5, 
                              vars_to_show = NULL) {

  numeric_data<- dplyr::select_if(data, is.numeric)

  #Make the list of boxplots
  
  boxplot_list<- show_all_boxplots(data, identifier)

  #Make the list of density plots
  
  density_list<- show_all_density_plots(data, gaussian_kernel)
  
  #Make the list of histograms

  histogram_list<- show_all_histograms(data)
  
  #Iterate through the plot-specific lists to make a new list 
  #containing 3 distributions per variable

  plots_list<- purrr::pmap(list(boxplot_list, density_list, histogram_list),
                           ~plotly::subplot(..1, ..2, ..3, titleY = TRUE))

  names(plots_list)<- names(numeric_data)
  
  #Subset the whole dataframe if the user makes a selection of variables
  #Each set of three distributions forms a row of the subplot
  
  if(is.null(vars_to_show)) {

  plotly::subplot(plots_list, nrows = length(plots_list), titleY = TRUE)

  } else {

  plotly::subplot(plots_list[vars_to_show], nrows = 
                    length(plots_list[vars_to_show]), titleY = TRUE)

  }

}
```

Finally, test the `show_distributions()` function with a selction of four variables:


```r
show_distributions(mtcars, identifier = "car_name", vars_to_show = c("mpg", "disp", "drat", "qsec"))
```

preserve988d94a21e177e8a

Hopefully this article gives you some idea of how to use functional programming to
increase your visualisation efficiency in R. I'd love to hear your thoughts!

</body>
