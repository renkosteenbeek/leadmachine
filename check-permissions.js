import 'dotenv/config';
import { ConfidentialClientApplication } from '@azure/msal-node';

const msalConfig = {
  auth: {
    clientId: process.env.GRAPH_CLIENT_ID,
    clientSecret: process.env.GRAPH_CLIENT_SECRET,
    authority: `https://login.microsoftonline.com/${process.env.GRAPH_TENANT_ID}`,
  }
};

const cca = new ConfidentialClientApplication(msalConfig);

async function checkPermissions() {
  try {
    console.log('App Configuration:');
    console.log('Client ID:', process.env.GRAPH_CLIENT_ID);
    console.log('Tenant ID:', process.env.GRAPH_TENANT_ID);
    console.log('');

    console.log('Acquiring access token...');
    const tokenResponse = await cca.acquireTokenByClientCredential({
      scopes: ['https://graph.microsoft.com/.default']
    });

    console.log('✓ Token acquired successfully\n');

    const token = tokenResponse.accessToken;
    const tokenPayload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());

    console.log('Token Details:');
    console.log('================');
    console.log('Issued at:', new Date(tokenPayload.iat * 1000).toLocaleString('nl-NL'));
    console.log('Expires at:', new Date(tokenPayload.exp * 1000).toLocaleString('nl-NL'));
    console.log('App ID:', tokenPayload.appid);
    console.log('Tenant ID:', tokenPayload.tid);
    console.log('');

    console.log('Granted Permissions (roles):');
    console.log('================');
    if (tokenPayload.roles && tokenPayload.roles.length > 0) {
      tokenPayload.roles.forEach(role => {
        console.log('✓', role);
      });
    } else {
      console.log('❌ No roles/permissions found in token');
      console.log('');
      console.log('This means:');
      console.log('1. API permissions not added in Azure Portal, OR');
      console.log('2. Admin consent not granted, OR');
      console.log('3. Changes not yet propagated (wait 5-10 minutes)');
    }
    console.log('');

    console.log('Required permissions for this app:');
    console.log('- Mail.Send (to send emails)');
    console.log('- Mail.Read (to read emails)');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkPermissions();
