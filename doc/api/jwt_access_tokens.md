### JWT Access Tokens for LTI2 Tools
Canvas JWT access tokens allow Tool Providers (TPs) to make Canvas API calls on behalf of a tool itself rather than a specific Canvas user. They can also be used to retrieve custom Tool Consumer Profiles (TCP) with restricted capabilities and register Tool Proxies with those restricted capabilities enabled.

Section 1.0 of this document describes how to retrieve a JWT access token for fetching custom TCPs and registering tools. Section 2.0 describes how to retrieve a JWT access token for use with LTI2 API. (such as the originality reports API).

**Note:** _to retrieve a custom Tool Consumer Profile an Instructure employee must first create the tool consumer profile and associate it with your developer key. Please contact us for assistance with this process._

For more information on JWTs see https://tools.ietf.org/html/rfc7519

#### 1.0 JWT Access Tokens for Custom TCPs and Tool Proxy Registration
JWT access tokens can be used to request custom Tool Consumer Profiles (TCP) with restricted capabilities/services and register Tool Proxies with those capabilities enabled.

To retrieve a JWT access token for this purpose first build a JWT using the following JWT as a template:

```javascript
my_jwt = {
  "sub": 10000000000003, // Canvas developer key global id
  // This URL is sent in the initial registration request as a param named 'oauth2_access_token_url'.
  "aud": "http://my.canvas.com/api/lti/accounts/1/authorize",
  "exp": 1486393868, // expiration time
  "iat": 1486393800, // issued at
  "jti": "688700c2-4bc1-40b7-83e5-7cbf54f93335" // Random UUID for request (must be unique for each request)
}
```

Next, sign the JWT using the developer key associated with the global ID used as the `sub` of the JWT that was just created. The HS256 algorithm should be used for signing.

```javascript
signed_jwt = my_jwt.sign(<my_dev_key_secret>).to_string
> "***REMOVED***"
```

We highly recommend using a library to create and sign these tokens.

Then, make a request to the authorization endpoint to retrieve your JWT access token. The URL you should use to make this request is sent in the initial registration request sent from Canvas as a parameter named oauth2_access_token_url.

The signed JWT should be used as the `assertion` parameter, the `grant_type` parameter should be set to `authorization_code`, and the `code` parameter should be set to the value of the `reg_key` received from the registration message sent by the tool consumer.

**Example request:**
```
curl https://<canvas>/api/lti/accounts/1/authorize \
       -F 'grant_type=authorization_code' \
       -F'assertion=***REMOVED***' \
       -F 'code=<reg_key>'
```
**Example response:**
```json
{
  "access_token":"***REMOVED***",
  "token_type": "bearer",
  "expires_in": "3600"
}

```
This token may be used in retrieving a custom TCP and registering a Tool Proxy with restricted capabilities if included in the authorization header:

```
Authorization Bearer <JWT access_token>
```

#### 2.0 JWT Access Tokens for LTI2 APIs
Use of JWT access tokens with the Canvas API is restricted to a set of endpoints which currently includes Originality Report and Subscription create, edit, and update. JWT access tokens are only valid for tools who register as described in section 1 of this document.

To retrieve a JWT access token first build a JWT using the following JWT as a template:

```javascript
my_jwt = {
  "sub": "123123-ad13-ac233", // tool proxy guid
  "aud": "https://my.canvas-domain.com/api/lti/accounts/1/authorize", // authorization URL used for authorization request
  "exp": 1486393868, // expiration time
  "iat": 1486393800, // issued at
  "jti": "688700c2-4bc1-40b7-83e5-7cbf54f93305" // Random UUID for request
}
```

Next, sign the JWT using the tool proxy shared secret and HS256:
```javascript
signed_jwt = my_jwt.sign("tool-proxy-shared-secret").to_string
> "***REMOVED***"
```

We highly recommend using a library to create and sign these tokens.

Next make a request to the authorization endpoint to retrieve your JWT access token. The URL you should use to make this request if sent in the initial registration request sent from Canvas as a parameter named `oauth2_access_token_url`.


This signed JWT should be used as the `assertion` parameter and the `grant_type` parameter  should be set to `urn:ietf:params:oauth:grant-type:jwt-bearer`

**Example request:**
```
curl https://<canvas>/api/lti/accounts/1/authorize \
       -F 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
       -F 'assertion=<signed_jwt>'
```

**Example response**
```json
{
  "access_token":"***REMOVED***",
  "token_type": "bearer",
  "expires_in": "3600"
}
```
The access token in the response can then be used in an API request to Originality Report and Submission endpoints.

**Example request**
```
curl https://<canvas>/api/lti/assignments/25/submissions/6/originality_report/71 \
       -F 'Authorization=Bearer <access_token from the authorize endpoint response>'
```

**Example response**
```json
{
   "id": 4,
   "file_id": 71,
   "originality_score": 25.2,
   "originality_report_file_id": 17,
   "originality_report_url": "http://www.example.com/report"
}
```
