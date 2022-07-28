class @DrawingChart
  constructor: (options = {}) ->
    @properties = options

  setChart: (options) ->
    _.extend @properties, options

  drawBarChart: (data, gateways, updateTime) ->
    data ||= @properties.data
    gateways ||= @properties.gateways
    gateway_names = Object.keys(gateways)

    $(document).ready =>
      @highchart = new Highcharts.Chart
        chart:
          renderTo: 'container'
          type: 'column'
        title:
          text: 'Latest Performance'
        subtitle:
          text: "Last Update: #{updateTime}"
        xAxis:
          categories: gateway_names
          labels:
            formatter: ->
              "#{this.value}<br>#{gateways[this.value]}"
        yAxis:
          min: 0
          title:
            text: 'Speed (Mbps)'
          labels:
            overflow: 'justify'
        tooltip:
          formatter: ->
            "#{this.series.name} #{this.x}: <strong>#{this.y.toFixed(2)}</strong> Mbps"
          backgroundColor: '#fff'
        series: data

  drawLineChart: (categoriesData, data, chartName, timeRange) ->
    $(document).ready =>
      @highchart = new Highcharts.Chart
        chart:
          renderTo: 'container'
          type: 'spline'
        title:
          text: chartName
        subtitle:
          text: "Time range: #{timeRange}"
        xAxis:
          categories: categoriesData
        yAxis:
          title:
            text: 'Speed (Mbps)'
          plotLines: [
            value: 0
            width: 1
            color: '#808080'
          ]
          min: 0
        tooltip:
          formatter: ->
            "<em>#{this.x}</em><br>#{this.series.name}<br/><strong>#{this.y.toFixed(2)}</strong> Mbps"
        series: data
