'use strict'

const KVBackend = require('./kv-backend')
const zlib = require('zlib')

/** Secrets Manager backend class. */
class SecretsManagerBackend extends KVBackend {
  /**
   * Create Secrets Manager backend.
   * @param {Object} client - Client for interacting with Secrets Manager.
   * @param {Object} logger - Logger for logging stuff.
   */
  constructor ({ clientFactory, assumeRole, logger }) {
    super({ logger })
    this._client = clientFactory()
    this._clientFactory = clientFactory
    this._assumeRole = assumeRole
  }

  /**
   * Get secret property value from Secrets Manager.
   * @param {string} key - Key used to store secret property value in Secrets Manager.
   * @param {object} keyOptions - Options for this specific key, eg version etc.
   * @param {string} keyOptions.versionStage - Version stage
   * @param {object} specOptions - Options for this external secret, eg role
   * @param {string} specOptions.roleArn - IAM role arn to assume
   * @returns {Promise} Promise object representing secret property value.
   */
  async _get ({ key, specOptions: { roleArn, compressed }, keyOptions: { versionStage = 'AWSCURRENT' } }) {
    this._logger.info(`fetching secret property ${key} with role: ${roleArn || 'pods role'}`)

    let client = this._client
    if (roleArn) {
      const res = await this._assumeRole({
        RoleArn: roleArn,
        RoleSessionName: 'k8s-external-secrets'
      })
      client = this._clientFactory({
        accessKeyId: res.Credentials.AccessKeyId,
        secretAccessKey: res.Credentials.SecretAccessKey,
        sessionToken: res.Credentials.SessionToken
      })
    }

    const data = await client
      .getSecretValue({ SecretId: key, VersionStage: versionStage })
      .promise()

    if ('SecretBinary' in data) {
      if (compressed) {
        const decompressed = await this._decompress(data.SecretBinary)
        return decompressed
      }
      return data.SecretBinary
    } else if ('SecretString' in data) {
      if (compressed) {
        const decompressed = await this._decompress(data.SecretString)
        return decompressed
      }
      return data.SecretString
    }

    this._logger.error(`Unexpected data from Secrets Manager secret ${key}`)
    return null
  }

  async _decompress (data) {
    return new Promise(resolve => {
      zlib.unzip(data, function (err, decompressed) {
        if (err) {
          throw err
        }
        resolve(decompressed)
      })
    })
  }
}

module.exports = SecretsManagerBackend
