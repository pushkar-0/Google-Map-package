import { LightningElement,api } from 'lwc';
export default class AccountGoogleMapFilterScreenChild extends LightningElement {
// @api sobjectField;
// @api sobjectData;
// @api selectedObjectName;
// @api sobject;
// @api isLookUp;

//  addressInputChange(event) {
//         console.log('event is called::', JSON.stringify(event.target.dataset.id));
//         const agentAddressObj = {
//             Street: event.target.street ? event.target.street : null,
//             City: event.target.city ? event.target.city : null,
//             State: event.target.province ? event.target.province : null,
//             Country: event.target.country ? event.target.country : null,
//             PostalCode: event.target.postalCode ? event.target.postalCode : null,
//             Latitude: this.latitude? this.latitude : null,
//             Longitude: this.longitude? this.longitude : null

//         };
//         this.agentAddress = agentAddressObj;
//         console.log('event is called1::');
//         console.log('Updated Agent Address:', JSON.stringify(this.agentAddress));
//         if (this.sobjectData) {
//             this.updateSelectedValues(this.selectedObjectName, event.target.dataset.id, JSON.stringify(this.agentAddress));
//         }

//     }


//      updateSelectedValues(objectName, fieldAPIName, selectedValue) {
//         console.log('fieldAPIName::', fieldAPIName);
//         console.log('selectedValue::', selectedValue);
//         // Iterate over the response data to find the matching ObjectName
//         this.sobjectData.forEach(obj => {
//             if (obj.ObjectName === objectName) {
//                 // Find the field with the matching fieldAPIName
//                 obj.lstFieldDetails.forEach(field => {
//                     if (field.fieldAPIName === fieldAPIName) {
//                         // Update the selectedValues for the matching field
//                         field.selectedValues = selectedValue;
//                         console.log(`Updated ${fieldAPIName} in ${objectName} with selected value:`, selectedValue);
//                     }
//                 });
//             }
//         });
//         console.log('Updated responseData:', JSON.stringify(this.sobjectData, null, 2));
//     }

//      handlePicklistChange(event) {
//         console.log('string event change::', event.target.value);
//         console.log('string event change event.key::', event.target.dataset.id);
//         if (this.sobjectData) {
//             this.updateSelectedValues(this.selectedObjectName, event.target.dataset.id, event.target.value);
//         }
//     }

//     handleStringChange(event) {
//         console.log('string event change::', event.target.value);
//         console.log('string event change event.key::', event.target.dataset.id);
//         if (this.sobjectData) {
//             const valueToUpdate = event.target.value ? event.target.value : null;
//             this.updateSelectedValues(this.selectedObjectName, event.target.dataset.id, valueToUpdate);
//         }

//     }


}