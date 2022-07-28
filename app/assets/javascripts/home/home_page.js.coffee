class @HomePage
  constructor: ->
    @initiateDatePicker()
    @bindAjaxLoader()
    @bindFilterChart()
    @bindManualUpdate()
    @bindLatestResult()
    @bindToggleUpload()
    @bindGatewaySelect()
    @chart = new Chart()

  initiateDatePicker: ->
    @$dateInput = $('#date-input')
    @start = @end = moment().format('YYYY-MM-DD')
    @setDateInput(moment(), moment())

    dateTrigger = $('#date-trigger')
    dateTrigger.daterangepicker
      format: 'MM/DD/YYYY'
      startDate: moment()
      endDate: moment()
      minDate: moment().subtract(90, 'days')
      maxDate: moment()
      dateLimit:
        days: 90
      showDropdowns: true
      showWeekNumbers: false
      timePicker: false
      timePickerIncrement: 1
      timePicker12Hour: true
      ranges:
        'Today': [moment(), moment()]
        'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')]
        'Last 7 Days': [moment().subtract(6, 'days'), moment()]
        'Last 30 Days': [moment().subtract(29, 'days'), moment()]
        'Last 60 Days': [moment().subtract(59, 'days'), moment()]
        'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
      opens: 'left'
      drops: 'down'
      buttonClasses: ['btn', 'btn-sm']
      applyClass: 'btn-primary'
      cancelClass: 'btn-default'
      separator: ' to '
      locale:
        applyLabel: 'Update'
        cancelLabel: 'Cancel'
        fromLabel: 'From'
        toLabel: 'To'
        customRangeLabel: 'Custom'
        daysOfWeek: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr','Sa']
        monthNames: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
        firstDay: 1
    , (start, end, label) =>
      @start = start.format('YYYY-MM-DD')
      @end = end.format('YYYY-MM-DD')
      @setDateInput(start, end)

    dateTrigger.on 'apply.daterangepicker', @ajaxRequestLineChart

  bindAjaxLoader: ->
    @$loading = $("#loading")
    $(document).on "ajaxSend", =>
      @$loading.show()
    .on "ajaxComplete", =>
      @$loading.hide()

  bindFilterChart: ->
    $("#submit-button").on 'click', @ajaxRequestLineChart

  bindManualUpdate: ->
    @$manualUpdate = $('#manual-update')
    @$manualUpdate.on 'click', (event) =>
      if !@$manualUpdate.prop('disabled')
        vex.dialog.prompt
          message: 'Please enter password to start manual speed test:'
          callback: (password) =>
            @ajaxRequestUpdateSpeed(password)

  bindLatestResult: ->
    $('#show-latest').on 'click', =>
      @chart.ajaxRequestBarChart()
      @$toggleUpload.find('i').attr('class', 'glyphicon glyphicon-eye-close')

  bindToggleUpload: ->
    @$toggleUpload = $('#toggle-upload')
    @$toggleUpload.on 'click', (event) =>
      series = @chart.drawingChart.highchart.series
      $icon = @$toggleUpload.find('.glyphicon-eye-close')
      if $icon.length
        for i in [0 .. series.length - 1] by 2
          series[i].hide()
        $icon.attr('class', 'glyphicon glyphicon-eye-open')
      else
        for serie in series
          serie.show()
        @$toggleUpload.find('i').attr('class', 'glyphicon glyphicon-eye-close')

  bindGatewaySelect: ->
    @$selectedGateway = $('#selected-gateway');
    @$dropdownAvatar = $('.dropdown-avatar');
    $('.gateway').on 'click', (event) =>
      @$selectedGateway.html($(event.currentTarget).html())
      @$dropdownAvatar.html(@getCodeName($(event.currentTarget).find('h3').text()))
      @ajaxRequestLineChart()

  ajaxRequestLineChart: =>
    @chart.ajaxRequestLineChart
      selected_gateway: @$selectedGateway.find('span').text()
      start: @start
      end: @end
    @$toggleUpload.find('i').attr('class', 'glyphicon glyphicon-eye-close')

  ajaxRequestUpdateSpeed: (password) ->
    $.ajax
      type: "GET"
      data: { password: password }
      url: "/networks/manual_update"
      success: (data) =>
        vex.dialog.alert(data['message'])
        if data.success
          setTimeout(@enableUpdateButton, 600000)
        else
          @enableUpdateButton()

  enableUpdateButton: ->
    @$manualUpdate.prop("disabled", false)

  getCodeName: (text) ->
    if text.length > 2
      text[0] + text[1] + text[text.length - 1]
    else
      text

  setDateInput: (start, end) ->
    @$dateInput.html("#{start.format('DD MMMM')} — #{end.format('DD MMMM')}")
