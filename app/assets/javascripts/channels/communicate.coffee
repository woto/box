App.communicate = App.cable.subscriptions.create "CommunicateChannel",
  connected: ->
    $('#websocket-status').text('on')

  disconnected: ->
    $('#websocket-status').text('off')

  received: (data) ->
    $('tbody').prepend('<tr><td>'+JSON.stringify(data)+'</td></tr>');

  status: ->
    @perform 'status'
