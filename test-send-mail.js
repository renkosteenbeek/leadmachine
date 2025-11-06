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

async function sendTestEmail() {
  try {
    console.log('Acquiring access token...');
    const tokenResponse = await cca.acquireTokenByClientCredential({
      scopes: ['https://graph.microsoft.com/.default']
    });

    const accessToken = tokenResponse.accessToken;
    console.log('✓ Token acquired successfully\n');

    const client = Client.init({
      authProvider: (done) => {
        done(null, accessToken);
      }
    });

    const fromEmail = process.env.SENDER_EMAIL;
    const toEmail = process.env.ADMIN_EMAIL;

    console.log(`Sending test email...`);
    console.log(`From: ${fromEmail}`);
    console.log(`To: ${toEmail}\n`);

    const message = {
      message: {
        subject: 'Test Email from LeadMachine',
        body: {
          contentType: 'HTML',
          content: `
            <html>
              <body>
                <h2>Test Email</h2>
                <p>Dit is een test email verstuurd vanuit LeadMachine.</p>
                <p>Tijdstip: ${new Date().toLocaleString('nl-NL')}</p>
                <hr>
                <p style="color: #666; font-size: 12px;">
                  Deze email is verstuurd via Microsoft Graph API
                </p>
              </body>
            </html>
          `
        },
        toRecipients: [
          {
            emailAddress: {
              address: toEmail
            }
          }
        ]
      }
    };

    await client
      .api(`/users/${fromEmail}/sendMail`)
      .post(message);

    console.log('✓ Email successfully sent!');
    console.log('\nCheck your inbox at:', toEmail);

  } catch (error) {
    console.error('❌ Error sending email:', error.message);
    if (error.statusCode) {
      console.error('Status code:', error.statusCode);
    }
    if (error.body) {
      console.error('Error details:', JSON.stringify(error.body, null, 2));
    }
  }
}

sendTestEmail();
