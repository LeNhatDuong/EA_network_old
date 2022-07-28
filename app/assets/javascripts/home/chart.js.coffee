class @Chart
  constructor: ->
    @drawingChart = new DrawingChart()

    @ajaxRequestBarChart()

  ajaxRequestBarChart: (params) ->
    params ||= {}
    $.ajax
      type: "GET",
      url: "/charts",
      data: params,
      success: (data) =>
        @updateBarChart(data["data"], data["gateways"])

  ajaxRequestLineChart: (params) ->
    params ||= {}
    $.ajax
      type: "GET",
      url: "/charts/filter",
      data: params,
      success: (data) =>
        if data.error && data.error.length != 0
          vex.dialog.alert("Error: #{data.error}")
        else
          @updateLineChart(data)

  updateBarChart: (data, gateways) ->
    upload_data = { name: 'Upload', data: [] }
    download_data = { name: 'Download', data: [] }

    $.each gateways, (index) =>
      upload_data.data.push(data[index].upload)
      download_data.data.push(data[index].download)

    highchartsOptions = Highcharts.setOptions(Highcharts.bar)
    updateTime = moment(data[Object.keys(data)[0]].updated_at).format('D MMMM • HH:mm:ss')
    @drawingChart.drawBarChart([upload_data, download_data], gateways, updateTime)

  updateLineChart: (response_data) ->
    chartType = response_data.type
    data = response_data.data
    categoriesData = @getCategoriesData(data)

    highchartsOptions = Highcharts.setOptions(Highcharts.line)
    @drawingChart.drawLineChart(categoriesData, @gatewayData(chartType, data, categoriesData), response_data.chart_name, response_data.time_range)

  getCategoriesData: (data) ->
    categoriesData = []
    $.each data, (index, gatewayData) ->
      $.each gatewayData.performances, (index, value) =>
        categoriesData.push(value.label) if !_.contains(categoriesData, value.label)

    _.sortBy categoriesData, (time) ->
      Date.parse(time)

  gatewayData: (type, data, categoriesData) ->
    chartData = []

    $.each data, (index, gatewayData) =>
      name = if type == ALL_CHART then " #{gatewayData.name}" else ""
      upload_data = { "name": "Upload#{name}", "data": [] }
      download_data = { "name": "Download#{name}", "data": [] }

      $.each gatewayData.performances, (index, values) ->
        upload_data.data.push([categoriesData.indexOf(values.label), values.upload])
        download_data.data.push([categoriesData.indexOf(values.label), values.download])

      chartData.push upload_data
      chartData.push download_data

    chartData
