import { LightningElement, track } from 'lwc';
import getsObjectAddress from '@salesforce/apex/SobjectKizzyMapController.getsObjectAddress';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getKizzyMapFilterDdata from '@salesforce/apex/SobjectKizzyMapController.getKizzyMapFilterDdata';

export default class AccountsGoogleMapFilterScreen extends LightningElement {
    agentAddress;
    radius;
    @track sobject;
    @track street;
    @track city;
    @track country;
    @track postalCode;
    @track state;
    @track isUpdate = true;
    timeSpan = 100;
    @track isLoading = false;
    sObjectAddressFieldName;
    longitude;
    latitude;

    objectOptions = [];
    sobjectData;
    isLookUp = true;
    isChecked = false;
    @track selectedObjectFields = [];
    @track selectedObjectName = '';
    debounceTimeout;

    connectedCallback() {
        this.init();
    }

    init() {
        this.isLoading = true;
        getKizzyMapFilterDdata()
            .then(result => {
                if (result.isSuccess) {
                    this.sobjectData = JSON.parse(result.response);
                    this.objectOptions = this.sobjectData.map(record => ({ label: record.ObjectName, value: record.ObjectName }));

                    const defaultObject = this.sobjectData.find(record => record.Order === 0);
                    if (defaultObject) this.processDefaultObject(defaultObject);
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error in init:', error);
                this.isLoading = false;
            });
    }

    handleChange(event) {
        this.isLoading = true;
        this.selectedObjectName = event.target.value;
        const defaultObject = this.sobjectData.find(record => record.ObjectName === this.selectedObjectName);
        this.isLookUp = false;

        if (defaultObject) this.processDefaultObject(defaultObject);

        this.clearAddressFields();
        this.isLoading = false;
    }

    handleStringChange(event) {
        this.handleFieldChange(event.target.dataset.id, event.target.value);
    }

    handlePicklistChange(event) {
        this.handleFieldChange(event.target.dataset.id, event.target.value);
    }

    handleCheckboxChange(event) {
        this.isChecked = event.target.checked;
        this.handleFieldChange(event.target.dataset.id, this.isChecked);
    }

    handleFieldChange(fieldAPIName, selectedValue) {
        if (this.sobjectData) {
            this.updateSelectedValues(this.selectedObjectName, fieldAPIName, selectedValue);
        }
    }

    processDefaultObject(defaultObject) {
        this.selectedObjectName = defaultObject.ObjectName;
        this.selectedObjectFields = defaultObject.lstFieldDetails.map(field => {
            let fieldObj = { ...field };
            if (field.dataType === 'ADDRESS') {
                this.sObjectAddressFieldName = field.fieldAPIName;
                fieldObj.isAddressField = true;
            } else if (field.dataType === 'PICKLIST') {
                fieldObj.isPicklistField = true;
            } else if (field.dataType === 'STRING') {
                fieldObj.isInputField = true;
            } else if (field.dataType === 'BOOLEAN') {
                fieldObj.isBooleanField = true;
            }
            return fieldObj;
        });

        if (!this.selectedObjectFields || this.selectedObjectFields.length === 0) {
            this.showToast('error', 'Missing filter condition record for Address field.', null);
        }
    }

    updateSelectedValues(objectName, fieldAPIName, selectedValue) {
        const object = this.sobjectData.find(obj => obj.ObjectName === objectName);
        if (object) {
            const field = object.lstFieldDetails.find(f => f.fieldAPIName === fieldAPIName);
            if (field) field.selectedValues = selectedValue;
        }
    }

    get lookupDataId() {
        const addressField = this.selectedObjectFields.find(field => field.isAddressField);
        return addressField ? addressField.fieldAPIName : 'defaultDataId';
    }

    addressInputChange(event) {
        const agentAddressObj = {
            Street: event.target.street || null,
            City: event.target.city || null,
            State: event.target.province || null,
            Country: event.target.country || null,
            PostalCode: event.target.postalCode || null,
            Latitude: this.latitude || null,
            Longitude: this.longitude || null
        };
        this.agentAddress = agentAddressObj;
        if (this.sobjectData) {
            this.updateSelectedValues(this.selectedObjectName, event.target.dataset.id, JSON.stringify(this.agentAddress));
        }
    }

    handelLookUpDataChange(event) {
        this.sobject = event.detail.inputValue;
        this.handleAddressUpdate(this.sobject, this.selectedObjectName);
    }

    handleAddressUpdate(accDetails, selectedObjectName) {
        this.isLoading = true;
        if (accDetails) {
            getsObjectAddress({
                sobjectId: this.sobject,
                fieldName: this.sObjectAddressFieldName
            })
                .then(result => {
                    if (result.isSuccess) {
                        const address = JSON.parse(result.response).Address;
                        const sObjectAddress = JSON.parse(address);

                        this.updateAddressFields(sObjectAddress);
                        if (this.sobjectData) {
                            this.updateSelectedValues(selectedObjectName, this.sObjectAddressFieldName, JSON.stringify(this.agentAddress));
                        }

                        this.isLoading = false;
                    }
                })
                .catch(error => {
                    console.error('Error in handleAddressUpdate:', error);
                    this.isLoading = false;
                });
        } else {
            this.clearAddressFields();
            this.isLoading = false;
        }
    }

    updateAddressFields(sObjectAddress) {
        this.street = sObjectAddress.street;
        this.city = sObjectAddress.city;
        this.country = sObjectAddress.country;
        this.postalCode = sObjectAddress.postalCode;
        this.state = sObjectAddress.state;
        this.longitude = sObjectAddress.longitude;
        this.latitude = sObjectAddress.latitude;

        this.agentAddress = {
            Street: this.street,
            City: this.city,
            State: this.state,
            Country: this.country,
            PostalCode: this.postalCode,
            Latitude: this.latitude,
            Longitude: this.longitude
        };
    }

    clearAddressFields() {
        this.street = null;
        this.city = null;
        this.country = null;
        this.postalCode = null;
        this.state = null;
        this.sobject = null;
        this.isLookUp = true;
    }

    radiusInputChange(event) {
        this.radius = event.target.value;
    }

    handleClear() {
        this.closePopup();
    }

    handleApply() {
        console.log('this.agentAddress::',JSON.stringify(this.agentAddress));
        console.log('this.sobjectData::',JSON.stringify(this.sobjectData));
        if (this.isFormValid()) {
            this.handleFireEvent('apply', this.agentAddress, this.radius, this.sobjectData);
            this.closePopup();
        } else {
            console.log('Form validation failed.');
        }
    }

    closePopup() {
        this.dispatchEvent(new CustomEvent('closepopup'));
    }

    isFormValid() {
        return [...this.template.querySelectorAll('.validate')]
            .every(inputCmp => inputCmp.checkValidity());
    }

    handleFireEvent(eventName, agentAddress, radius, sobjectData) {
        this.dispatchEvent(new CustomEvent('apply', {
            detail: { agentAddress, radius, sobjectData, sObjectName: this.selectedObjectName, fieldAPIName: this.sObjectAddressFieldName },
            bubbles: true,
            composed: true
        }));
    }

    showToast(variant, title, message) {
        this.dispatchEvent(new ShowToastEvent({ variant, title, message }));
    }
}