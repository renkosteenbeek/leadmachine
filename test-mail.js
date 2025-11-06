import 'dotenv/config';
import { ConfidentialClientApplication } from '@azure/msal-node';
import { Client } from '@microsoft/microsoft-graph-client';

const msalConfig = {
  auth: {
    clientId: process.env.GRAPH_CLIENT_ID,
    clientSecret: process.env.GRAPH_CLIENT_SECRET,
    authority: `https://login.microsoftonline.com/${process.env.GRAPH_TENANT_ID}`,
  }
};

const cca = new ConfidentialClientApplication(msalConfig);

async function getAccessToken() {
  const tokenRequest = {
    scopes: ['https://graph.microsoft.com/.default']
  };

  try {
    const response = await cca.acquireTokenByClientCredential(tokenRequest);
    return response.accessToken;
  } catch (error) {
    console.error('Error acquiring token:', error);
    throw error;
  }
}

async function readEmails() {
  try {
    console.log('Acquiring access token...');
    const tokenResponse = await cca.acquireTokenByClientCredential({
      scopes: ['https://graph.microsoft.com/.default']
    });

    const accessToken = tokenResponse.accessToken;
    console.log('✓ Token acquired successfully');

    const tokenPayload = JSON.parse(Buffer.from(accessToken.split('.')[1], 'base64').toString());
    console.log('Token permissions (roles):', tokenPayload.roles || 'None');
    console.log('');

    const client = Client.init({
      authProvider: (done) => {
        done(null, accessToken);
      }
    });

    const userEmail = process.env.SENDER_EMAIL;
    console.log(`Reading emails from: ${userEmail}\n`);

    const messages = await client
      .api(`/users/${userEmail}/messages`)
      .top(5)
      .select('subject,from,receivedDateTime,bodyPreview')
      .orderby('receivedDateTime DESC')
      .get();

    console.log(`Found ${messages.value.length} emails:\n`);

    messages.value.forEach((msg, index) => {
      console.log(`${index + 1}. ${msg.subject}`);
      console.log(`   From: ${msg.from.emailAddress.address}`);
      console.log(`   Date: ${new Date(msg.receivedDateTime).toLocaleString()}`);
      console.log(`   Preview: ${msg.bodyPreview.substring(0, 100)}...`);
      console.log('');
    });

  } catch (error) {
    console.error('Error reading emails:', error.message);
    if (error.statusCode) {
      console.error('Status code:', error.statusCode);
    }
    if (error.body) {
      console.error('Error details:', JSON.stringify(error.body, null, 2));
    }
    console.log('\n⚠️  To fix this error:');
    console.log('1. Go to Azure Portal: https://portal.azure.com');
    console.log('2. Navigate to: Azure Active Directory → App registrations');
    console.log(`3. Find your app with Client ID: ${process.env.GRAPH_CLIENT_ID}`);
    console.log('4. Go to: API permissions');
    console.log('5. Add these Application permissions:');
    console.log('   - Mail.Read or Mail.ReadBasic.All');
    console.log('6. Click "Grant admin consent" button');
  }
}

readEmails();
