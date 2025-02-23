import { LightningElement, track, wire } from 'lwc';
import getAgentCoordinates from '@salesforce/apex/SobjectKizzyMapController.getAgentCoordinates';
import getNearbysObject from '@salesforce/apex/SobjectKizzyMapController.getNearbysObject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, subscribe, MessageContext } from 'lightning/messageService';
import MAP_MARKERS_MESSAGE from '@salesforce/messageChannel/MapMarkersMessageChannel__c';
export default class AccountsGoogleMap extends LightningElement {
    @track mapMarkers = [];
    @track markersTitle = "Sobject Postal details";
    isPopupVisible = false;
    @track isData = false;
    zoomLevel;
    @track accountData = false;
    @track isLoading = true;
    @track subscription = null;
    timeSpan = 2100;
    @track radius;
    @track agentAddress;

    // Flag to prevent recursion during zoom events
    processingZoom = false;
    //Added by: Pushkar on 28.01.025
    sobjectName;
    addressDetails;
    @track mapMarkerTitle = [];
    sObjectId;
    latitude;
    longitude;
    // LMS Context
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.init();
    }

    // Initializes one marker and add to the array
    init() {
        var marker = {
            location: {
                Country: 'USA'
            },
        };
        this.mapMarkers.push(marker);

        console.log('Marker:', JSON.stringify(marker, null, 2));
        console.log('Map Markers:', JSON.stringify(this.mapMarkers, null, 2));

        this.isData = true;
        this.zoomLevel = 5;

        // Send map markers via LMS
        this.subscribeToMapMarkers();
        this.publishMarkersToLMS();

        this.toggelSpinner();
    }

    subscribeToMapMarkers() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.messageContext, MAP_MARKERS_MESSAGE, (message) => {
            this.handleReceivedMarkers(message);
        });
    }

    // handleReceivedMarkers(message) {
    //     try {
    //         console.log('handleReceivedMarkers from LMS:', JSON.stringify(message, null, 2));
    //         const actionType = message?.data?.actionType;
    //         const previousZoomLevel = message?.data?.previousZoomLevel;
    //         if (actionType === 'zoomChange' && previousZoomLevel != null && this.agentAddress) {
    //             this.handleGetCoordinates(this.agentAddress, previousZoomLevel);
    //         }
    //     } catch (error) {
    //         console.error('Error handling received markers:', error);
    //     }
    // }

    handleReceivedMarkers(message) {
        try {
            console.log('handleReceivedMarkers from LMS:', JSON.stringify(message, null, 2));

            const actionType = message?.data?.actionType;
            const isZoomEvent = message?.data?.isZoomEvent;
            if (actionType === 'zoomChange' && isZoomEvent && this.agentAddress && !this.processingZoom) {
                console.log('Processing zoom change event');
                this.processingZoom = true; // Set flag to true to indicate zoom processing is ongoing

                this.handleGetCoordinates(this.agentAddress, message.data.previousZoomLevel)
                    .then(() => {
                        this.processingZoom = false; // Reset flag after processing
                    })
                    .catch(() => {
                        this.processingZoom = false; // Reset flag in case of error
                    });
            }
        } catch (error) {
            console.error('Error handling received markers:', error);
        }
    }
    toggelSpinner() {
        this.event1 = setTimeout(() => {
            this.handlespinnerFalse();
        }, this.timeSpan);
    }

    handlespinnerFalse() {
        this.isLoading = false;
    }

    // Publish the mapMarkers using Lightning Message Service
    publishMarkersToLMS() {
        console.log('this.mapMarkers::', JSON.stringify(this.mapMarkers));
        console.log('this.radius::', JSON.stringify(this.radius));
        console.log('this.agentAddress::', JSON.stringify(this.agentAddress));
        console.log('this.messageContext::', JSON.stringify(this.messageContext));
        const payload = {
            markers: this.mapMarkers, // The data we want to send
            radius: this.radius,
            agentAddress: this.agentAddress
        };
        console.log('payload::', payload);
        console.log('payload::', JSON.stringify(payload));
        publish(this.messageContext, MAP_MARKERS_MESSAGE, payload); // Publish the payload
        console.log('Published map markers to LMS:', JSON.stringify(this.mapMarkers, null, 2));
    }
    // Gets the coordinated or sets the default coordinates
    handleFilter(event) {

        console.log('Event received from child:');
        console.log('Radius:', event.detail.radius);
        console.log('Agent Address:', JSON.stringify(event.detail.agentAddress, null, 2));
        console.log('SObject Data in Parent::', JSON.stringify(event.detail.sobjectData, null, 2));
        this.isLoading = true;
        this.isData = true;
        this.radius = event.detail.radius ?? null;
        this.agentAddress = event.detail.agentAddress ?? {};
        this.sobjectName = event.detail.sObjectName;

        //Added By : Pushkar on 28.01.025
        if (event.detail.agentAddress != null && event.detail.agentAddress.Longitude != null &&
            event.detail.agentAddress.Latitude != null && event.detail.sObjectName != null) {
            console.log('enter in if');

            if (event.detail.radius != null) {
                console.log('enter in 1st if');
                this.handleAccountDetails(event.detail.agentAddress.Longitude, event.detail.agentAddress.Latitude,
                    event.detail.radius, event.detail.sObjectName, event.detail.fieldAPIName, JSON.stringify(event.detail.sobjectData));
            }
            else {
                 console.log('enter in 2nd if');
                this.handleAccountDetails(event.detail.agentAddress.Longitude, event.detail.agentAddress.Latitude,
                    '10', event.detail.sObjectName, event.detail.fieldAPIName, JSON.stringify(event.detail.sobjectData));
            }
        }
        else if (event.detail.agentAddress != null && event.detail.radius != null) {
                console.log('enter in 3rd if');
            console.log('Valid agentAddress and radius provided. Proceeding to get coordinates.');

            this.handleGetCoordinates(event.detail.agentAddress, event.detail.radius, event.detail.sObjectName, event.detail.fieldAPIName, event.detail.sobjectData);
        }
        else {
            console.log(' Invalid agentAddress or radius. Initializing default marker.');
            this.handleGetCoordinates(event.detail.agentAddress, '10', event.detail.sObjectName, event.detail.fieldAPIName, event.detail.sobjectData);
        }
        this.toggelSpinner();
    }

    // Gets the agents coordinates  
    handleGetCoordinates(agentAddress, radius, sobjectName, fieldAPIName, sObjectData) {
        console.log('Agent Address:', JSON.stringify(agentAddress, null, 2));
        console.log('Radius:', JSON.stringify(radius, null, 2));
        console.log('SObject Data in handleGetCoordinates::', JSON.stringify(sObjectData, null, 2));
        let updatedsObjectData;
        // Gets the coordinates from the apex 
        getAgentCoordinates({
            address: JSON.stringify(agentAddress),
            radius: JSON.stringify(radius),
        })
            .then(result => {
                console.log('*** handleGetCoordinates .then *** ');

                if (result.isSuccess && result.message == 'Success') {
                    console.log('Result Response:', JSON.stringify(result.response, null, 2));

                    const agentCoordinates = JSON.parse(result.response);

                    console.log('Longitude:', agentCoordinates.longitude);
                    console.log('Latitude:', agentCoordinates.latitude);
                    if (agentCoordinates.longitude != null &&
                        agentCoordinates.latitude != null &&
                        sObjectData != null) {
                        updatedsObjectData = this.updateLatLongOnSobject(sObjectData, sobjectName,
                            fieldAPIName, agentCoordinates.latitude,
                            agentCoordinates.longitude);
                        console.log('returned JSON ::', JSON.stringify(updatedsObjectData, null, 2))
                    }

                    if (agentCoordinates.longitude != null && agentCoordinates.latitude != null &&
                        radius != null &&
                        updatedsObjectData != null) {
                        console.log(' Coordinates are valid. Proceeding to get account details.');
                        this.handleAccountDetails(agentCoordinates.longitude, agentCoordinates.latitude,
                            radius, sobjectName,
                            fieldAPIName, JSON.stringify(updatedsObjectData));
                    } else {
                        console.log(' Invalid coordinates or radius ');
                        if (radius == null) {
                            console.log('Radius is null. Showing error toast.');
                            this.showToast('error', 'Error getting Agents coordinates !! ', null);
                        } else {
                            console.log(' Long/Lat is null. Showing error toast. ');
                            this.showToast('error', 'Error getting Agents Radius !! ', null);
                        }
                    }
                } else {
                    console.log('Coordinates retrieval failed message: ', result.message);
                    console.log('Coordinates retrieval failed response: ', result.response);

                    this.showToast('error', result.message, result.response);
                }
            })
            .catch(error => {
                console.log('*** handleGetCoordinates .catch *** ');
                console.log('*** handleGetCoordinates .catch ::: error.body.message *** ', error.body.message);
                this.showToast('Unsuccessful ', 'Error', error.body.message);
            })
    }

    updateLatLongOnSobject(jsonData, objectName, fieldAPIName, latitude, longitude) {
        jsonData.forEach((object) => {
            // Check if the object matches the dynamic objectName
            if (object.ObjectName === objectName) {
                // Iterate through field details
                object.lstFieldDetails.forEach((field) => {
                    // Check if the field matches the dynamic fieldAPIName
                    if (field.fieldAPIName === fieldAPIName) {
                        // Check if selectedValues exists and is valid JSON
                        if (field.selectedValues && field.selectedValues.trim() !== '') {
                            try {
                                let selectedValues = JSON.parse(field.selectedValues);
                                // Ensure latitude and longitude are numbers, not strings
                                if (!isNaN(latitude) && !isNaN(longitude)) {
                                    selectedValues.Latitude = Number(latitude);
                                    selectedValues.Longitude = Number(longitude);
                                    // Convert back to string after updating
                                    field.selectedValues = JSON.stringify(selectedValues);
                                } else {
                                    console.error('Invalid latitude or longitude values.');
                                }
                            } catch (error) {
                                console.error('Error parsing selectedValues JSON:', error);
                            }
                        } else {
                            console.error('No valid selectedValues found for field:', fieldAPIName);
                        }
                    }
                });
            }
        });

        console.log('SObject Data in handleGetCoordinates1::', JSON.stringify(jsonData, null, 2));
        return jsonData;
    }


    // Gets the nearby accountList
    handleAccountDetails(longitude, latitude, radius, sobjectName, fieldAPIName, sObject) {
        console.log('*** handleAccountDetails CALLED ***', sObject);
        // Make apex call to get the list of nearby accounts within the radius 
        getNearbysObject({ //JSON.stringify(latitude),
            radius: radius, // JSON.stringify(radius)
            sObjectName: sobjectName,
            fieldAPIName: fieldAPIName,
            sObjectData: sObject

        })
            .then(result => {
                console.log('*** handleAccountDetails .then ***'); //BEGIN
                this.mapMarkers = [];
                console.log(' handleAccountDetails  result.isSuccess  ', result.isSuccess);
                console.log('handleAccountDetails Result:', JSON.stringify(result, null, 2));

                if (result.isSuccess) {
                    console.log('Response:', JSON.stringify(result.response, null, 2));

                    let parsedData = JSON.parse(result.response);
                    console.log('Parsed Data:', JSON.stringify(parsedData, null, 2));

                    // Parse the response dynamically
                    let parsedDynamicData = this.parseDynamicFields(parsedData);
                    console.log('result::', JSON.stringify(parsedDynamicData));

                    let labelIndex = 1;

                    parsedData.forEach(eachRecord => {
                        console.log('Account Record:', JSON.stringify(eachRecord, null, 2));
                        // let sobjectAddress = JSON.parse(eachRecord.sObjectAddress.Address);

                        // console.log('eachRecord.sObjectAddress::', JSON.stringify(sobjectAddress));
                        // console.log('sobjectAddress.city::', JSON.stringify(sobjectAddress.city));
                        // if (sobjectAddress.longitude != null && sobjectAddress.latitude != null) {

                        console.log('*** Valid Long/Lat found ***', JSON.stringify(eachRecord, null, 2));
                        console.log('this.longitude22::', JSON.stringify(this.longitude));
                        console.log('this.latitude22::', JSON.stringify(this.latitude));

                        let center = {
                            index: labelIndex,
                            // title: sobjectAddress.street + ', ' + sobjectAddress.city + ', ' + sobjectAddress.state + ', ' + sobjectAddress.postalCode,
                            title: this.mapMarkerTitle,
                            address: this.addressDetails ? this.addressDetails : '',
                            Longitude: this.longitude,
                            Latitude: this.latitude,
                            sobject : this.sobjectName,
                            // label: eachRecord.sObjectName,
                            // clientType: eachRecord.clientType,
                            // location: {
                            //     Latitude: sobjectAddress.latitude,
                            //     Longitude: sobjectAddress.longitude,
                            // },
                            isOwner: eachRecord.isOwner,
                            Id: this.sObjectId
                        };
                        console.log('Center Marker:', JSON.stringify(center, null, 2));
                        this.mapMarkers.push(center);
                        console.log('Updated Map Markers:', JSON.stringify(this.mapMarkers, null, 2));
                        labelIndex++;
                        // }
                    });
                    // Re-publish the updated map markers via LMS
                    this.publishMarkersToLMS();
                    //this.dispatchMarkersEvent();
                    //this.isLoading = false;
                    console.log('*** AFTER LOOP ::: handleAccountDetails ::: this.mapMarkers ***', JSON.stringify(this.mapMarkers, null, 2));

                } else {
                    console.log('*** handleAccountDetails ::: result.isNOTSuccess *** ', result.isSuccess);
                    console.log('*** handleAccountDetails ::: result.isNOTSuccess *** ', JSON.stringify(result, null, 2));
                    this.showToast('Unsuccessful ', result.message, result.response);
                }
                this.accountData = true;
            })
            .catch(error => {
                console.log('*** handleAccountDetails .catch *** ');
                console.log('*** handleAccountDetails .catch ::: error.body.message *** ', error.message);
                //this.showToast('Unsuccessful ', 'Error', error.body.message);
            })
    }

    parseDynamicFields(jsonResponse) {
        let result = [];
        this.mapMarkerTitle = [];
        jsonResponse.forEach(record => {
            Object.keys(record.dynamicFields).forEach(key => {
                let fieldValue = record.dynamicFields[key];
                console.log('key::', key);
                // Check if the field contains serialized JSON (like BillingAddress)
                if (this.isValidJson(fieldValue)) {
                    console.log('enter in if ::');
                    // Parse the JSON string and merge it into the result
                    let parsedJson = JSON.parse(fieldValue);
                    // Check if parsedJson contains address-like fields and format accordingly
                    if (this.isAddressField(parsedJson)) {
                        console.log('Address-like field detected:', key);
                        console.log('parsedJson:', JSON.stringify(parsedJson));
                        // parsedFields[key] = this.formatAddress(parsedJson); // Format the address
                        this.addressDetails = this.formatAddress(parsedJson);
                    }
                }
                else if (key === 'Id') {
                    console.log('fieldValue::', fieldValue);
                    this.sObjectId = fieldValue;
                    // parsedFields[key] = parsedJson; // Add the parsed object as is
                } else if (key && !key.includes('Id')) {
                    console.log('else key::', key);
                    console.log('this.mapMarkerTitle before::',JSON.stringify(this.mapMarkerTitle));
                    if (fieldValue) {
                        this.mapMarkerTitle.push(fieldValue);
                        console.log('this.mapMarkerTitle::',JSON.stringify(this.mapMarkerTitle));
                    }
                }
            });
            // result.push(parsedFields);
        });
       this.mapMarkerTitle = (this.mapMarkerTitle && Array.isArray(this.mapMarkerTitle)) ? this.mapMarkerTitle.join(', ') : this.mapMarkerTitle;

        console.log('result1::', JSON.stringify(result));
        console.log(' this.this.mapMarkerTitle::', JSON.stringify(this.mapMarkerTitle));
        return result;
    }

    // Helper method to check if the object contains address-like fields
    isAddressField(addressObject) {
        return addressObject.hasOwnProperty('city') &&
            addressObject.hasOwnProperty('state') &&
            addressObject.hasOwnProperty('street');
    }

    // Helper method to format the address dynamically
    formatAddress(address) {
        let addressParts = [];
        if (address.street) addressParts.push(address.street);
        if (address.city) addressParts.push(address.city);
        if (address.state) addressParts.push(address.state);
        if (address.postalCode) addressParts.push(address.postalCode);
        if (address.country) addressParts.push(address.country);
        if (address.latitude) this.latitude = address.latitude;
        if (address.longitude) this.longitude = address.longitude;
        console.log('addressParts::', JSON.stringify(addressParts));

        // Join the non-empty address parts with a comma and space
        return addressParts.join(', ');
    }

    // Helper method to check if a string is valid JSON
    isValidJson(str) {
        try {
            JSON.parse(str);
        } catch (e) {
            return false;
        }
        return true;
    }

    handleNavigateToSobject(event) {
        console.log('enter in account navigate');
        const accountId = event.currentTarget.dataset.accountid;
        console.log('accountId::', accountId);
        const accountUrl = `/lightning/r/${this.sobjectName}/${accountId}/view`;
        window.open(accountUrl, '_blank');
    }

    handleMarkerHover(event) {
        console.log('enter in account hover');
        const markerIndex = event.currentTarget.dataset.markerIndex;
        const marker = this.mapMarkers[markerIndex];

        // Publish hover event through LMS
        const payload = {
            action: 'hover',
            markerId: markerIndex,
            markerData: marker
        };
        publish(this.messageContext, MAP_MARKERS_MESSAGE, payload);
    }

    handleMarkerUnhover(event) {
        console.log('enter in account unhover');
        // Publish unhover event through LMS
        const payload = {
            action: 'unhover',
            markerId: null
        };
        publish(this.messageContext, MAP_MARKERS_MESSAGE, payload);
    }

    // Opens the filter pop-up
    openFilterPopup() {
        this.isPopupVisible = !this.isPopupVisible;
    }

    // Closes the filter pop-up
    closeFilterPopup() {
        this.isPopupVisible = false;
    }

    // Custom Toast 
    showToast(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message,
        });
        this.dispatchEvent(event);
    }

}