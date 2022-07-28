Highcharts.line =
  colors: [
    '#a4e8ff'
    '#0099CC'
    '#FFFF99'
    '#FFCC00'
    '#ffc6c6'
    '#FF3333'
    '#b6e5a5'
    '#43931b'
  ]
  chart:
    marginTop: 120
    marginBottom: 70
  xAxis:
    labels:
      style:
        font: '300 13px Roboto, Arial'
  yAxis:
    title:
      margin: 20
  legend:
    align: 'left'
    itemStyle:
      font: '300 14px Roboto, Arial'
      lineHeight: '20px'
    x: 72
    y: 57
    itemWidth: 160

Highcharts.bar =
  colors: ['#8ede39', '#0aa89e']
  chart:
    plotBorderWidth: 1
    marginRight: 15
    marginBottom: 55
    marginLeft: 75
    marginTop: 70
  subtitle:
    useHTML: true
    style:
      color: '#337ab7'
      font: '300 16px Roboto, Arial'
    align: 'left'
    x: 72
    y: 44
  title:
    style:
      color: '#313534'
      font: '400 20px Roboto, Arial'
    align: 'left'
    x: 72
    y: 22
  xAxis:
    gridLineWidth: 1
    lineColor: '#a5c8c5'
    tickWidth: 0
    labels:
      style:
        color: '#313534'
        font: '400 15px Roboto, Arial'
    title:
      style:
        color: '#333'
        font: '300 14px Roboto, Arial'
  yAxis:
    lineColor: '#b5c5af'
    lineWidth: 1
    tickWidth: 0
    labels:
      style:
        color: '#313534'
        font: '300 11px Roboto, Arial'
    title:
      style:
        color: '#00afa0'
        font: '400 14px Roboto, Arial'
      align: 'middle'
      margin: 15
  plotOptions:
    column:
      dataLabels:
        enabled: true
    spline:
      lineWidth: 4
      states:
        hover:
          lineWidth: 6
      marker:
        enabled: true
  legend:
    align: 'right'
    verticalAlign: 'top'
    layout: 'horizontal'
    x: -40
    y: 4
    itemStyle:
      font: '300 16px Roboto, Arial'
      color: 'black'
    itemHoverStyle:
      color: '#00afa0'
    itemHiddenStyle:
      color: 'gray'
    floating: true
    borderWidth: 0
    padding: 0
    useHTML: true
  credits:
    enabled: false
  labels:
    style:
      color: '#99b'
