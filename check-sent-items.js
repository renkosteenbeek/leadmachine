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
const userEmail = process.env.SENDER_EMAIL;

async function checkSentItems() {
  try {
    const tokenResponse = await cca.acquireTokenByClientCredential({
      scopes: ['https://graph.microsoft.com/.default']
    });

    const client = Client.init({
      authProvider: (done) => {
        done(null, tokenResponse.accessToken);
      }
    });

    console.log('Checking Sent Items for forwarded emails...\n');

    const messages = await client
      .api(`/users/${userEmail}/mailFolders/sentitems/messages`)
      .select('subject,receivedDateTime,toRecipients,bodyPreview')
      .top(10)
      .orderby('receivedDateTime DESC')
      .get();

    console.log(`Found ${messages.value.length} recent sent emails:\n`);

    messages.value.forEach((msg, index) => {
      const to = msg.toRecipients.map(r => r.emailAddress.address).join(', ');
      console.log(`${index + 1}. ${msg.subject}`);
      console.log(`   To: ${to}`);
      console.log(`   Date: ${new Date(msg.receivedDateTime).toLocaleString('nl-NL')}`);

      if (msg.bodyPreview.includes('CPQ LEAD ANALYSE')) {
        console.log(`   🎯 THIS IS A FORWARDED CPQ LEAD!`);
        console.log(`   Preview: ${msg.bodyPreview.substring(0, 150)}...`);
      }
      console.log();
    });

  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkSentItems();
