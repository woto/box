App.communicate = App.cable.subscriptions.create "CommunicateChannel",
  connected: ->
    $('#websocket-status').text('on')

  disconnected: ->
    $('#websocket-status').text('off')

  received: (data) ->
    $('tbody').prepend('<tr><td>'+data+'</td></tr>');

  status: ->
    @perform 'status'
