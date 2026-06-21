def making_bar_charts():
    # Import relevant modules
    import pandas as pd
    import plotly_express as px

    # Read in vulnerable.csv file
    vulnerable = pd.read_csv("data/vulnerable.csv")

    # Filter years to only 1997
    vuln_filter = vulnerable[vulnerable["year"].isin([1997])]

    pivot_vuln_filter = vuln_filter.groupby("continent").agg({"country": "count"}).reset_index()

    pivot_vuln_filter = pivot_vuln_filter.rename(columns={"country": "count"})

    # Count the number of countries in each continent to be used to create labels
    column = vuln_filter.iloc[0:, 1]
    item_counts = column.value_counts()
    str_item_counts = [str(i) for i in item_counts]

    # Create a bar chart with continents listed on the y-axis
    vuln_plot = px.bar(
        pivot_vuln_filter,
        y="continent",
        x="count",
        labels={"count": "Number of Countries", "continent": "Continent"},
    )

    vuln_plot.update_layout(
        # Add title
        title=dict(
            text="Figure 1: Africa has the most countries by continent",
            font=dict(size=20),
            x=0.5,  # noqa
        ),
        # Add Source, Footnote and number labels at the end of bars
        annotations=[
            dict(
                text="Source: Pandemic Preparedness Toolkit",
                x=50,
                y=-0.4,
                showarrow=False,
                font=dict(size=12),
            ),
            dict(
                text="Note: Counts are based on boundaries in 1997.",
                x=50,
                y=-0.5,
                showarrow=False,
                font=dict(size=12),
            ),
        ],
    )

    # Add number labels at the end of bars
    vuln_plot.update_traces(text=str_item_counts, textposition="outside", textfont_size=20)

    # Order the bars by number of countries from largest to smallest
    vuln_plot.update_layout(yaxis={"categoryorder": "total ascending"})

    # Change the colours of bar chart bars (Top to Bottom)
    colours = ["#003d59", "lightgrey", "lightgrey", "lightgrey", "lightgrey"]
    vuln_plot.update_traces(marker_color=colours)

    # Show bar chart
    vuln_plot.show()

    vuln_plot.write_html("output/python_bar_chart.html")


making_bar_charts()
