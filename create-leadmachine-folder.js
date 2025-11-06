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

async function createLeadMachineFolder() {
  try {
    const tokenResponse = await cca.acquireTokenByClientCredential({
      scopes: ['https://graph.microsoft.com/.default']
    });

    const client = Client.init({
      authProvider: (done) => {
        done(null, tokenResponse.accessToken);
      }
    });

    console.log('Creating "leadmachine" folder...\n');

    const newFolder = await client
      .api(`/users/${userEmail}/mailFolders`)
      .post({
        displayName: 'leadmachine'
      });

    console.log('✓ Folder created successfully!');
    console.log(`  Name: ${newFolder.displayName}`);
    console.log(`  ID: ${newFolder.id}`);
    console.log('\nYou can now run the capability tests.\n');

  } catch (error) {
    if (error.statusCode === 409) {
      console.log('✓ Folder "leadmachine" already exists!');
    } else {
      console.error('❌ Error:', error.message);
      if (error.body) {
        console.error('Details:', JSON.stringify(error.body, null, 2));
      }
    }
  }
}

createLeadMachineFolder();
