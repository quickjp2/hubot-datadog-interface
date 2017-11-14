# Description
#    Talks with datadog on users' behalf
#
# Dependancies
#    dogapi
#
# Configuration:
#    HUBOT_DATADOG_APIKEY - Your Datadog API key
#    HUBOT_DATADOG_APPKEY - Your Datadog app Key
#    DATADOG_API_URL - Datadog api url, with trailing `/`
#
# Commands:
#    hubot in datadog, mute monitor <mon_id> for <1-999> second|minute|hour - mute monitor for x amount of time
#    hubot in datadog, unmute monitor <mon_id> - unmutes monitor
#    hubot in datadog, schedule downtime for foundation <found_name> for <1-999> second|minute|hour - schedule downtime
#    hubot in datadog, cancel downtime <dt_id> - cancel downtime by id
#    hubot in datadog, cancel all downtimes for foundation: <found_name> - cancel downtime by id
#    hubot in datadog, show status for downtime <dt_id> - show status for a specific downtime
#
# Notes:
#    <optional notes required for the script>
#
# Author:
#    JP Quicksall <john.paul.quicksall@gmail.com>

is_empty = (obj) ->
    return true if not obj? or obj.length is 0

    return false if obj.length? and obj.length > 0

    for key of obj
        return false if Object.prototype.hasOwnProperty.call(obj,key)

    return true

module.exports = (robot) ->
  robot.respond /hello/i, (msg) ->
    msg.reply "hello!"

  robot.hear /orly/i, (msg) ->
    msg.send "yarly"
  # Mute a monitor
  robot.respond /in datadog,? mute monitor (\d+) for (\d{1,3}) (second|minute|hour)s?/i, (msg) ->
    monitorId = msg.match[1]
    ending = parseInt(msg.match[2])
    scale = msg.match[3]
    url = process.env.DATADOG_API_URL + "monitor/#{monitorId}/mute?" +
          "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
          "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
    robot.logger.debug url
    robot.logger.debug("Muting monitor #{monitorId} for #{ending} #{scale}...")
    if /second/.test scale
      ending = ending
    else if /minute/i.test scale
      ending = ending * 60
    else if /hour/i.test scale
      ending = ending * 60 * 60
    else
      msg.send "Could you double check your scale? I'm not sure what you mean by #{scale}"
      return
    # dogapi.monitor.mute(monitorId, end=(parseInt(new Date().getTime() / 1000) + ending))
    robot.http(url)
      # .headers({'Content-Type': 'application/json'})
      .post(JSON.stringify({ end: (parseInt(new Date().getTime() / 1000) + ending) })) (err, res, body) ->
        if err
          robot.logger.warning "Encountered an error: #{err}"
          msg.send "Something went wrong"
          return
        robot.logger.debug res.statusCode
        response = JSON.parse body
        robot.logger.debug body
        if res.statusCode == 200
          msg.send "Muted #{response['modified']}"
        else
          payload = {
            title: "Error from datadog"
            fields: []
            color: "warning"
            pretext:  "Got back an error..."
          }
          count = 1
          for error in response.errors
            newErrorField = {
              title: "Error #{count}"
              value: error
            }
            payload.fields.push newErrorField
            count += 1
          msg.send {attachments:[payload]}
        # msg.send "Muted monitor"

  # Unmute a monitor
  robot.respond /in datadog,? unmute monitor (\d+)/i, (msg) ->
    monitorId = msg.match[1]
    url = process.env.DATADOG_API_URL + "monitor/#{monitorId}/unmute?" +
          "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
          "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
    robot.logger.debug url
    robot.logger.debug("Unmuting monitor #{monitorId}...")
    # dogapi.monitor.unmute(monitorId)
    robot.http(url)
      .headers({'Content-Type': 'application/json'})
      .post() (err, res, body) ->
        if err
          robot.logger.warning "Encountered an error: #{err}"
          msg.send "Something went wrong"
          return
        robot.logger.debug res.statusCode
        response = JSON.parse body
        robot.logger.debug body
        if res.statusCode == 200
          msg.send "Unmuted #{response['modified']}"
        else
          payload = {
            title: "Got an error back from datadog"
            fields: []
            color: "warning"
          }
          count = 1
          for error in response.errors
            newErrorField = {
              title: "Error #{count}"
              value: error
            }
            payload.fields.push
            count += 1
          msg.send {attachments:[payload]}, "Got back an error..."

  # Show status - currently provides no relevent info, making this currently "useless"
  robot.respond /in datadog,? show status for monitor (\d+)/i, (msg) ->
    monitorId = msg.match[1]
    url = process.env.DATADOG_API_URL + "monitor/#{monitorId}?" +
          "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
          "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
    robot.logger.debug url
    robot.logger.debug("Getting details for monitor #{monitorId}...")
    # dogapi.monitor.unmute(monitorId)
    robot.http(url)
      .get() (err, res, body) ->
        if err
          robot.logger.warning "Encountered an error: #{err}"
          msg.send "Something went wrong"
          return
        robot.logger.debug res.statusCode
        robot.logger.debug body
        if res.statusCode == 200
          response = JSON.parse body
          payload = {
            title: "Monitor: #{response.name}",
            pretext: "Showing status for monitor #{monitorId}",
            text: unless response.message? then "No message available" else response.message,
            fallback: "No message available; falling back",
            fields: [
              {
                title: "Creator",
                value: "#{response.creator.handle}",
                short: true
              },
              {
                title: "Status",
                value: "#{if is_empty response.options.silenced then 'Unmuted' else 'Muted'}",
                short: true
              }
            ]
          }
          robot.logger.debug JSON.stringify payload
          msg.send {attachments:[payload]}, ""
        else
          payload = {
            title: "Got an error back from datadog"
            fields: []
            color: "warning"
          }
          count = 1
          for error in response.errors
            newErrorField = {
              title: "Error #{count}"
              value: error
            }
            payload.fields.push
            count += 1
          msg.send {attachments:[payload]}, "Got back an error..."

  # Unmute a monitor
  robot.respond /in datadog,? schedule downtime for foundation (.+) for (\d+) (second|minute|hour)s?/i, (msg) ->
    foundation = msg.match[1]
    ending = parseInt(msg.match[2])
    scale = msg.match[3]
    url = process.env.DATADOG_API_URL + "downtime?" +
          "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
          "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
    robot.logger.debug url
    robot.logger.debug("Muting monitor #{foundation} for #{ending} #{scale}...")
    if /second/.test scale
      ending = ending
    else if /minute/i.test scale
      ending = ending * 60
    else if /hour/i.test scale
      ending = ending * 60 * 60
    else
      msg.send "Could you double check your scale? I'm not sure what you mean by #{scale}"
      return
    # dogapi.monitor.unmute(monitorId)
    payload = {
      scope: "foundation:#{foundation}",
      end: (new Date().getTime() / 1000) + ending
    }
    robot.logger.debug payload
    robot.http(url)
      .headers( {'Content-Type': 'application/json'})
      .post( JSON.stringify(payload) ) (err, res, body) ->
        if err
          robot.logger.warning "Encountered an error: #{err}"
          msg.send "Something went wrong"
          return
        response = JSON.parse body
        robot.logger.debug body
        robot.logger.debug res.statusCode
        msg.send "Downtime #{response['id']} scheduled for #{response['scope'][0]} until #{new Date(response['end'])}"

  robot.respond /in datadog,? cancel downtime (\d+)/i, (msg) ->
    downtimeId = msg.match[1]
    url = process.env.DATADOG_API_URL + "downtime/#{downtimeId}?" +
          "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
          "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
    robot.http(url)
      .delete() (err, res, body) ->
        if err
          robot.logger.warning "Encountered an error: #{err}"
          msg.send "Something went wrong"
          return
        robot.logger.debug body
        robot.logger.debug res.statusCode
        # if res.statusCode == 200
        #   response = JSON.parse body
        msg.send "Downtime #{downtimeId} cancelled"

  # Need More API info before finishing
  # robot.respond /in datadog,? cancel all downtimes for foundation:? (\w+)/i, (msg) ->
  #   foundation = msg.match[1]
  #   url = process.env.DATADOG_API_URL + "downtime/cancel/by_scope?" +
  #         "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
  #         "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
  #   payload = { scope: "foundation:#{foundation}"}
  #   robot.http(url)
  #     .headers( {'Content-Type': 'application/json'})
  #     .post( JSON.stringify(payload) ) (err, res, body) ->
  #       if err
  #         robot.logger.warning "Encountered an error: #{err}"
  #         msg.send "Something went wrong"
  #         return
  #       # response = JSON.parse body
  #       robot.logger.debug body
  #       robot.logger.debug res.statusCode

  #       msg.send "Downtimes cancelled"

  robot.respond /in datadog,? show status for downtime (\d+)/i, (msg) ->
    downtimeId = msg.match[1]
    url = process.env.DATADOG_API_URL + "downtime/#{downtimeId}?" +
          "api_key=#{process.env.HUBOT_DATADOG_APIKEY}&" +
          "application_key=#{process.env.HUBOT_DATADOG_APPKEY}"
    robot.http(url)
      .get() (err, res, body) ->
        if err
          robot.logger.warning "Encountered an error: #{err}"
          msg.send "Something went wrong"
          return
        robot.logger.debug body
        robot.logger.debug res.statusCode
        if res.statusCode == 200
          response = JSON.parse body
          payload = {
            title: "Showing status for downtime #{downtimeId}",
            text: response.message ? "No message available",
            fallback: "No message available; falling back",
            fields: [
              {
                title: "Active",
                value: "#{response.active}",
                short: true
              },
              {
                title: "Canceled",
                value: if response.canceled? then new Date(response.canceled * 1000).toString() else "N/A"
                short: true
              },
              {
                title: "Disabled",
                value: "#{response.disabled}",
                short: true
              },
              {
                title: "Scopes",
                value: response.scope.join("\n")
              }
            ]
          }
          msg.send {attachments:[payload]}
        else
          msg.send "Something went wrong with loading the json..."
