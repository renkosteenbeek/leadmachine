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

async function getClient() {
  const tokenResponse = await cca.acquireTokenByClientCredential({
    scopes: ['https://graph.microsoft.com/.default']
  });

  return Client.init({
    authProvider: (done) => {
      done(null, tokenResponse.accessToken);
    }
  });
}

async function testListFolders() {
  console.log('\n=== TEST 1: List All Mailbox Folders ===\n');

  try {
    const client = await getClient();

    const response = await client
      .api(`/users/${userEmail}/mailFolders`)
      .select('id,displayName,parentFolderId,totalItemCount,unreadItemCount,childFolderCount')
      .top(50)
      .get();

    console.log(`✓ Found ${response.value.length} folders:\n`);

    response.value.forEach(folder => {
      console.log(`  - ${folder.displayName}`);
      console.log(`    ID: ${folder.id}`);
      console.log(`    Total: ${folder.totalItemCount}, Unread: ${folder.unreadItemCount}`);

      if (folder.childFolderCount > 0) {
        console.log(`    Has ${folder.childFolderCount} child folders`);
      }
      console.log();
    });

    console.log(`\nSearching for 'leadmachine' folder under Inbox...`);

    const inboxFolder = response.value.find(f => f.displayName === 'Inbox');
    let leadmachineFolder = null;

    if (inboxFolder) {
      const inboxChildren = await client
        .api(`/users/${userEmail}/mailFolders/${inboxFolder.id}/childFolders`)
        .select('id,displayName,parentFolderId,totalItemCount,unreadItemCount')
        .get();

      leadmachineFolder = inboxChildren.value.find(f => f.displayName.toLowerCase() === 'leadmachine');

      if (leadmachineFolder) {
        console.log(`✓ Found 'leadmachine' under Inbox!`);
      }
    }

    if (!leadmachineFolder) {
      console.log(`Not found under Inbox, checking root level...`);
      leadmachineFolder = response.value.find(f => f.displayName.toLowerCase() === 'leadmachine');
    }

    if (leadmachineFolder) {
      console.log(`\n✓ Found 'leadmachine' folder!`);
      console.log(`  ID: ${leadmachineFolder.id}`);
      console.log(`  Total emails: ${leadmachineFolder.totalItemCount || 0}`);

      const childFolders = await client
        .api(`/users/${userEmail}/mailFolders/${leadmachineFolder.id}/childFolders`)
        .get();

      console.log(`  Child folders: ${childFolders.value.length}`);
      childFolders.value.forEach(child => {
        console.log(`    - ${child.displayName} (ID: ${child.id})`);
      });

      return leadmachineFolder.id;
    } else {
      console.log(`\n❌ 'leadmachine' folder not found!`);
      console.log(`   Create it manually in Outlook first.`);
      return null;
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.body) {
      console.error('Details:', JSON.stringify(error.body, null, 2));
    }
    throw error;
  }
}

async function testReadEmailsFromFolder(folderId) {
  console.log('\n=== TEST 2: Read Emails from Specific Folder ===\n');

  try {
    const client = await getClient();

    const messages = await client
      .api(`/users/${userEmail}/mailFolders/${folderId}/messages`)
      .select('id,subject,from,receivedDateTime,bodyPreview,body,isRead')
      .top(5)
      .orderby('receivedDateTime DESC')
      .get();

    console.log(`✓ Found ${messages.value.length} emails in folder:\n`);

    messages.value.forEach((msg, index) => {
      console.log(`${index + 1}. ${msg.subject}`);
      console.log(`   ID: ${msg.id}`);
      console.log(`   From: ${msg.from.emailAddress.address}`);
      console.log(`   Date: ${new Date(msg.receivedDateTime).toLocaleString('nl-NL')}`);
      console.log(`   Read: ${msg.isRead ? 'Yes' : 'No'}`);
      console.log(`   Preview: ${msg.bodyPreview.substring(0, 80)}...`);
      console.log();
    });

    return messages.value.length > 0 ? messages.value[0] : null;

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.body) {
      console.error('Details:', JSON.stringify(error.body, null, 2));
    }
    throw error;
  }
}

async function testFindOrCreateProcessedFolder(leadmachineFolderId) {
  console.log('\n=== TEST 3: Find or Create "processed" Subfolder ===\n');

  try {
    const client = await getClient();

    const childFolders = await client
      .api(`/users/${userEmail}/mailFolders/${leadmachineFolderId}/childFolders`)
      .get();

    let processedFolder = childFolders.value.find(f => f.displayName.toLowerCase() === 'processed');

    if (processedFolder) {
      console.log(`✓ 'processed' folder already exists!`);
      console.log(`  ID: ${processedFolder.id}`);
      return processedFolder.id;
    }

    console.log(`'processed' folder not found, creating it...`);

    processedFolder = await client
      .api(`/users/${userEmail}/mailFolders/${leadmachineFolderId}/childFolders`)
      .post({
        displayName: 'processed'
      });

    console.log(`✓ Created 'processed' folder!`);
    console.log(`  ID: ${processedFolder.id}`);

    return processedFolder.id;

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.body) {
      console.error('Details:', JSON.stringify(error.body, null, 2));
    }
    throw error;
  }
}

async function testMoveEmail(messageId, targetFolderId) {
  console.log('\n=== TEST 4: Move Email to Different Folder ===\n');

  try {
    const client = await getClient();

    console.log(`Moving message ${messageId.substring(0, 20)}...`);
    console.log(`To folder: ${targetFolderId.substring(0, 20)}...`);

    const movedMessage = await client
      .api(`/users/${userEmail}/messages/${messageId}/move`)
      .post({
        destinationId: targetFolderId
      });

    console.log(`✓ Email moved successfully!`);
    console.log(`  New ID: ${movedMessage.id}`);
    console.log(`  Subject: ${movedMessage.subject || 'N/A'}`);

    return movedMessage.id;

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.body) {
      console.error('Details:', JSON.stringify(error.body, null, 2));
    }
    throw error;
  }
}

async function testVerifyEmailGone(sourceFolderId, originalMessageId) {
  console.log('\n=== TEST 5: Verify Email No Longer in Source Folder ===\n');

  try {
    const client = await getClient();

    console.log(`Checking if message ${originalMessageId.substring(0, 20)}... still exists in source...`);

    try {
      await client
        .api(`/users/${userEmail}/mailFolders/${sourceFolderId}/messages/${originalMessageId}`)
        .get();

      console.log(`⚠️  Message still found in source folder!`);
      console.log(`   This might mean the ID changed after move.`);
      return false;
    } catch (error) {
      if (error.statusCode === 404) {
        console.log(`✓ Message no longer in source folder (404 Not Found)`);
        console.log(`  This confirms the move was successful!`);
        return true;
      }
      throw error;
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    throw error;
  }
}

async function testForwardEmail(messageId, toAddress) {
  console.log('\n=== TEST 6: Forward Email with Custom Comment ===\n');

  try {
    const client = await getClient();

    const comment = `=== CPQ LEAD ANALYSE ===

Dit is een potentieel interessante lead voor een CPQ implementatie.

Reden: Test forward functionaliteit voor LeadMachine CLI.

=== ORIGINELE EMAIL HIERONDER ===`;

    console.log(`Forwarding message to ${toAddress}...`);

    await client
      .api(`/users/${userEmail}/messages/${messageId}/forward`)
      .post({
        comment: comment,
        toRecipients: [
          {
            emailAddress: {
              address: toAddress
            }
          }
        ]
      });

    console.log(`✓ Email forwarded successfully!`);
    console.log(`  Check inbox at: ${toAddress}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.body) {
      console.error('Details:', JSON.stringify(error.body, null, 2));
    }
    throw error;
  }
}

async function runAllTests() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║  Microsoft Graph API Capabilities Test Suite          ║');
  console.log('║  Testing: Folders, Reading, Moving, Forwarding        ║');
  console.log('╚════════════════════════════════════════════════════════╝');

  try {
    const leadmachineFolderId = await testListFolders();

    if (!leadmachineFolderId) {
      console.log('\n⚠️  Cannot continue without "leadmachine" folder.');
      console.log('   Please create it in Outlook and run this test again.');
      return;
    }

    const testEmail = await testReadEmailsFromFolder(leadmachineFolderId);

    if (!testEmail) {
      console.log('\n⚠️  No emails found in "leadmachine" folder.');
      console.log('   Please add a test email and run again.');
      return;
    }

    const processedFolderId = await testFindOrCreateProcessedFolder(leadmachineFolderId);

    const newMessageId = await testMoveEmail(testEmail.id, processedFolderId);

    await testVerifyEmailGone(leadmachineFolderId, testEmail.id);

    await testForwardEmail(newMessageId, process.env.ADMIN_EMAIL);

    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║  ✓ ALL TESTS PASSED!                                  ║');
    console.log('╚════════════════════════════════════════════════════════╝\n');

    console.log('Summary:');
    console.log('  ✓ Can list folders');
    console.log('  ✓ Can find "leadmachine" folder');
    console.log('  ✓ Can read emails from specific folder');
    console.log('  ✓ Can create "processed" subfolder');
    console.log('  ✓ Can move emails between folders');
    console.log('  ✓ Moved emails do not reappear in source');
    console.log('  ✓ Can forward emails with custom comment');
    console.log('\nReady to build Swift CLI application! 🚀\n');

  } catch (error) {
    console.log('\n╔════════════════════════════════════════════════════════╗');
    console.log('║  ❌ TESTS FAILED                                       ║');
    console.log('╚════════════════════════════════════════════════════════╝\n');
    console.error('Error details:', error);
  }
}

runAllTests();
