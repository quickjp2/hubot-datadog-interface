Helper = require('hubot-test-helper')
chai = require 'chai'
nock = require('nock')
sinon = require('sinon')
chai.use = require('sinon-chai')

expect = chai.expect

helper = new Helper('../src/datadog-interface.coffee')

# Define globals
process.env.HUBOT_DATADOG_APIKEY = "9775a026f1ca7d1c6c5af9d94d9595a4"
process.env.HUBOT_DATADOG_APPKEY = "87ce4a24b5553d2e482ea8a8500e71b8ad4554ff"
process.env.DATADOG_API_URL = "https://app.datadoghq.com/api/v1/"
process.env.LOG_LEVEL = "debug"

testMonitorId = 123456
testDowntimeId = 234567891

describe 'datadog-interface', ->
  # room = null
  beforeEach ->
    nock.disableNetConnect()
    nock('https://app.datadoghq.com/api/v1')
      # .log(console.log)
      .post('/monitor/' + testMonitorId + '/mute', {end: /\d+/})
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply(200, {
        "tags":["*"],
        "deleted":null,
        "query":"avg(last_5m):avg:jmx.org.cloudfoundry.opentsdb.nozzle.mysql.mysql_performance_busy_time{deployment:cf,!foundry:tt-stg} by {foundry,job,ip} >= 90",
        "message":"Percentage of CPU time spent by MySQL on user activity, executing user code, as opposed to kernel activity processing system calls.\n\nUse: This closely reflects the amount of server activity dedicated to app queries.\n\n- If this metric meets or exceeds the recommended thresholds for extended periods of time, run SHOW PROCESSLIST and identify which queries or apps are using so much CPU. Optionally redeploy the MySQL jobs using VMs with more CPU capacity.\n- Run mysql-diag and check the MySQL Server logs for errors.\n @slack-cfalerts @cfops@t-mobile.com",
        "id":testMonitorId,
        "multi":true,
        "name":"{{foundry.name}} {{job.name}} {{ip.name}} MySQL CPU Busy Time",
        "created":"2017-10-24T17:49:10.700197+00:00",
        "created_at":1508867350000,
        "org_id":62267,
        "modified":"2017-10-24T17:49:10.700197+00:00",
        "overall_state_modified":"2017-10-24T17:52:17.105987+00:00",
        "overall_state":"OK",
        "type":"metric alert",
        "options":{
          "notify_audit":false,
          "locked":false,
          "timeout_h":0,
          "silenced": {
            "*":null
          },
          "include_tags":false,
          "no_data_timeframe":null,
          "require_full_window":true,
          "new_host_delay":300,
          "notify_no_data":false,
          "renotify_interval":0,
          "escalation_message":"",
          "thresholds":{
            "critical":90.0,
            "warning":80.0
          }
        }
      })
      .post('/monitor/' + testMonitorId + '/unmute')
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply(200, {
        "tags":["*"],
        "deleted":null,
        "query":"i<=90",
        "message":"This is a message to include in the monitor",
        "id": testMonitorId,
        "multi":true,
        "name":"Monitor One",
        "created":"2017-10-24T17:49:10.700197+00:00",
        "created_at":1508867350000,
        "org_id":62267,
        "modified":"2017-10-24T17:49:10.700197+00:00",
        "overall_state_modified":"2017-10-24T17:52:17.105987+00:00",
        "overall_state":"OK",
        "type":"metric alert",
        "options":{
          "notify_audit":false,
          "locked":false,
          "timeout_h":0,
          "silenced":{},
          "include_tags":false,
          "no_data_timeframe":null,
          "require_full_window":true,
          "new_host_delay":300,
          "notify_no_data":false,
          "renotify_interval":0,
          "escalation_message":"",
          "thresholds":{
            "critical":90.0,
            "warning":80.0
          }
        }
      })
      .get('/monitor/' + testMonitorId)
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply(200, {
        "tags":["*"],
        "deleted":null,
        "query":"i<=90",
        "message":"This is a message to include in the monitor",
        "id":testMonitorId,
        "multi":true,
        "name":"Monitor One",
        "created":"2017-10-24T17:49:10.700197+00:00",
        "created_at":1508867350000,
        "org_id": 62267,
        "modified":"2017-10-24T17:49:10.700197+00:00",
        "overall_state_modified":"2017-10-24T17:52:17.105987+00:00",
        "overall_state":"OK",
        "type":"metric alert",
        "options":{
          "notify_audit":false,
          "locked":false,
          "timeout_h":0,
          "silenced":{},
          "include_tags":false,
          "no_data_timeframe":null,
          "require_full_window":true,
          "new_host_delay":300,
          "notify_no_data":false,
          "renotify_interval":0,
          "escalation_message":"",
          "thresholds":{
            "critical":90.0,
            "warning":80.0
          }
        },
        "creator": {
          "id": 517798,
          "handle": "person@example.com",
          "name": null,
          "email": "person@example.com"
        }
      })
      .post('/downtime', {scope: "foundation:npe", end: /\d+/})
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply(200, {
        "disabled":false,
        "canceled":null,
        "active":true,
        "timezone":"UTC",
        "message":null,
        "id":testDowntimeId,
        "end":1508867350000,
        "parent_id":null,
        "monitor_id":null,
        "recurrence":null,
        "start":1510012092,
        "creator_id":479688,
        "scope":[
          "foundation:npe"
        ],
        "updater_id":null
      })
      .delete("/downtime/#{testDowntimeId}")
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply(204)
      .get("/downtime/#{testDowntimeId}")
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply(200, {
        "disabled":true,
        "canceled":1510083239,
        "active":false
        "timezone":"UTC",
        "message":null,
        "id":261089902,
        "end":1510012804,
        "parent_id":null,
        "monitor_id":null,
        "recurrence":null,
        "start":1510012744,
        "creator_id":479688,
        "scope":["foundation:px-npe01"],
        "updater_id":479688
      })
      .post("/downtime/cancel/by_scope")
      .query({api_key: process.env.HUBOT_DATADOG_APIKEY, application_key: process.env.HUBOT_DATADOG_APPKEY})
      .reply()
    @room = helper.createRoom()
    @robot =
      respond: sinon.spy()

  afterEach ->
    @room.destroy()
    nock.cleanAll()

  it 'mutes a monitor for 30 seconds', ->
    @room.user.say('alice', "@hubot in datadog mute monitor #{testMonitorId} for 30 seconds").then =>
      expect(@room.messages).to.eql [
        ['alice', "@hubot in datadog mute monitor #{testMonitorId} for 30 seconds"]
        ['hubot', 'Muted 2017-10-24T17:49:10.700197+00:00']
      ]
  it 'unmutes a monitor', ->
    @room.user.say('bob', "@hubot in datadog, unmute monitor 123456").then =>
      expect(@room.messages).to.eql [
        ['bob', "@hubot in datadog, unmute monitor 123456"]
        ['hubot', 'Unmuted 2017-10-24T17:49:10.700197+00:00']
      ]
  it 'shows the status of a monitor', ->
    @room.user.say('bob', 'in datadog, show status for monitor 123456').then =>
      expect(@room.messages).to.eql [
        ['bob', 'in datadog, show status for monitor 123456']
        # ['hubot', 'yarly']
      ]
  it 'schedules downtime for a foundation for 30 seconds', ->
    @room.user.say('bob', '@hubot in datadog, schedule downtime for foundation npe for 30 seconds').then =>
      expect(@room.messages).to.eql [
        ['bob', '@hubot in datadog, schedule downtime for foundation npe for 30 seconds']
        ['hubot', "Downtime #{testDowntimeId} scheduled for foundation:npe until Tue Oct 24 2017 10:49:10 GMT-0700 (Pacific Daylight Time)"]
      ]
  it 'cancels a downtime by id', ->
    @room.user.say('bob', "@hubot in datadog cancel downtime #{testDowntimeId}").then =>
      expect(@room.messages).to.eql [
        ['bob', "@hubot in datadog cancel downtime #{testDowntimeId}"]
        ['hubot', "Downtime #{testDowntimeId} cancelled"]
      ]
  # it 'cancels all downtimes for a foundation', ->
  #   @room.user.say('bob', "@hubot in datadog, cancel all downtimes for foundation: npe").then =>
  #     expect(@room.messages).to.eql [
  #       ['bob', '@hubot in datadog, cancel all downtimes for foundation: npe']
  #       ['hubot', "Downtime #{testDowntimeId} cancelled"]
  #     ]
  it 'shows the status of a downtime', ->
    @room.user.say('bob', "@hubot in datadog, show status for downtime #{testDowntimeId}").then =>
      expect(@room.messages).to.eql [
        ['bob', "@hubot in datadog, show status for downtime #{testDowntimeId}"]
        ['hubot', {
          attachments: [{
          fallback: "No message available; falling back"
          text: "No message available"
          title: "Showing status for downtime 234567891"
          fields: [{
            short: true
            title: "Active"
            value: "false"
          }
          {
            short: true
            title: "Canceled"
            value: "Tue Nov 07 2017 11:33:59 GMT-0800 (Pacific Standard Time)"
          }
          {
            short: true
            title: "Disabled"
            value: "true"
          }
          {
            title: "Scopes"
            value: "foundation:px-npe01"
          }]}]}]]
