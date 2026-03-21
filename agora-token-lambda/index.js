// lambda/agora-token/index.js
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

exports.handler = async (event) => {
  // Handle both REST (API Gateway) and direct invocations
  const body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
  const { channelName, uid = 0 } = body;

  if (!channelName) {
    return {
      statusCode: 400,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'channelName is required' }),
    };
  }

  const token = RtcTokenBuilder.buildTokenWithUid(
    process.env.AGORA_APP_ID,
    process.env.AGORA_APP_CERTIFICATE,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    Math.floor(Date.now() / 1000) + 3600,
  );

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*', // tighten in prod
    },
    body: JSON.stringify({ token }),
  };
};