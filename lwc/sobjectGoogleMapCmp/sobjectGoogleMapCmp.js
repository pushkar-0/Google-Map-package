import { LightningElement, track } from 'lwc';
import getGoogleMapFilterDdata from '@salesforce/apex/SobjectGoogleMapController.getGoogleMapFilterDdata';
export default class SobjectGoogleMapCmp extends LightningElement {
    objectOptions = [];
    @track selectedObjectFields = [];
    @track selectedObjectName = '';
    connectedCallback() {
        this.init();
    }
    init() {
        getGoogleMapFilterDdata({})
            .then(result => {
                console.log('enter in connected CallBack:::', result);

                if (result.isSuccess) {
                    let data = JSON.parse(result.response);
                    console.log('enter in connected parse:::', JSON.stringify(data, null, 2));
                    this.objectOptions = data.map(record => {
                        return { label: record.ObjectName, value: record.ObjectName };
                    });
                    console.log('this.objectOptions::', JSON.stringify(this.objectOptions));
                    const defaultObject = data.find(record => record.Order === 0);
                    if (defaultObject) {
                        this.selectedObjectName = defaultObject.ObjectName;
                        this.selectedObjectFields = defaultObject.lstFieldDetails.map(field => {
                            // Create a base object and conditionally add the isAddressField or isPicklistField properties
                            let fieldObj = { ...field };
                            // Conditionally add the isAddressField property
                            if (field.dataType === 'ADDRESS') {
                                fieldObj.isAddressField = true;
                            }
                            // Conditionally add the isPicklistField property
                            else if (field.dataType === 'PICKLIST') {
                                fieldObj.isPicklistField = true;
                            }

                             else if (field.dataType === 'STRING') {
                                fieldObj.isInputField = true;
                            }
                            return fieldObj;
                        });
                        console.log('this.selectedObjectFields ::', JSON.stringify(this.selectedObjectFields));
                    }
                }

            })
            .catch(error => {
                console.log('error::', error);
            })
    }

}