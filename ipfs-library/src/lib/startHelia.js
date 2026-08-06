import { createHelia, heliaDefaults } from 'helia';
import { IDBBlockstore } from "blockstore-idb";
import { IDBDatastore } from "datastore-idb";
export async function iniciarHelia(){
    const blockstore = new IDBBlockstore('ipfsbooks-blocks');
    await blockstore.open();

    const datastore = new IDBDatastore('ipfsbooks-data');
    await datastore.open();

    const helia = await createHelia({
        blockstore: blockstore,
        datastore: datastore
    })

    return helia;
}