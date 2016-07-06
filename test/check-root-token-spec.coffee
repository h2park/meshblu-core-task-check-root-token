Datastore        = require 'meshblu-core-datastore'
mongojs          = require 'mongojs'
RootTokenManager = require 'meshblu-core-manager-root-token'
CheckRootToken   = require '../'

describe 'CheckRootToken', ->
  beforeEach (done) ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback null, uuid
    database = mongojs 'meshblu-core-task-check-token', ['devices']
    @datastore = new Datastore
      database: database
      collection: 'devices'

    database.devices.remove done

  beforeEach ->
    @rootTokenManager = new RootTokenManager { @datastore, @uuidAliasResolver }
    @sut = new CheckRootToken { @datastore, @uuidAliasResolver }

  describe '->do', ->
    context 'when given a valid token', ->
      beforeEach (done) ->
        record =
          uuid: 'thank-you-for-considering'
        @datastore.insert record, done

      beforeEach (done) ->
        @rootTokenManager.generateAndStoreToken { uuid: 'thank-you-for-considering' }, (error, @generatedToken) =>
          done error

      beforeEach (done) ->
        request =
          metadata:
            responseId: 'used-as-biofuel'
            auth:
              uuid: 'thank-you-for-considering'
              token: @generatedToken

        @sut.do request, (error, @response) => done error

      it 'should respond with a 204', ->
        expectedResponse =
          metadata:
            responseId: 'used-as-biofuel'
            code: 204
            status: 'No Content'

        expect(@response).to.deep.equal expectedResponse

    context 'when given a invalid token', ->
      beforeEach (done) ->
        record =
          uuid: 'thank-you-for-considering'
          token: 'this-will-not-work'
        @datastore.insert record, done

      beforeEach (done) ->
        request =
          metadata:
            responseId: 'axed'
            auth:
              uuid: 'hatcheted'
              token: 'bodysprayed'

        @sut.do request, (error, @response) => done error

      it 'should respond with a 401', ->
        expectedResponse =
          metadata:
            responseId: 'axed'
            code: 401
            status: 'Unauthorized'

        expect(@response).to.deep.equal expectedResponse
