import { LightningElement, track } from 'lwc';
import handleUserLocationTravel from '@salesforce/apex/UserLocationTravelCmpController.handleUserLocationTravel';
import Id from '@salesforce/user/Id'; // Import current user Id

export default class UserLocationTravelCmp extends LightningElement {
    @track monthOptions = [];
    @track selectedMonth;
    @track currentMonth;
    @track totalDistanceCovered = 0;
    @track defaultStartYear = new Date().getFullYear();
    @track yearOptions = [];
    @track isLoading = true;
    @track lstOfUserOptions = [];
    @track selectedUser;
    @track disableUserPicklist = true;
    @track isFirstLoad = true;

    connectedCallback() {
        console.log('[UserLocationTravelCmp] connectedCallback triggered', this.defaultStartYear);
        this.selectedUser = Id;
        this.initializeMonthOptions(); // Load month options
        this.setYearOption(); // Set year options
        this.loadTravelDataForUser(); // Fetch initial data for logged-in user
    }

    // Fetch travel data for the selected user
    loadTravelDataForUser() {
        this.isLoading = true;
        console.log('[UserLocationTravelCmp] Entry - Fetching travel data for user:', this.selectedUser, 'for month/year:', this.currentMonth, this.defaultStartYear);

        // Call Apex method to fetch data
        handleUserLocationTravel({
            currentMonth: this.currentMonth,
            currentYear: this.defaultStartYear,
            userId: this.selectedUser
        })
            .then(result => {
                if (result.isSuccess) {
                    let fetchedData = JSON.parse(result.response);
                    this.totalDistanceCovered = fetchedData?.totalDistanceCovered ?? 0;
                    console.log('totalDistanceCovered::', this.totalDistanceCovered);
                    this.lstOfUserOptions = fetchedData?.lstOfUserOptions ?? [];
                    this.isLoading = false;
                    console.log('[UserLocationTravelCmp] Data loaded lstOfUserOptions:', JSON.stringify(this.lstOfUserOptions, null, 2));
                    console.log('[UserLocationTravelCmp] Data loaded successfully:', JSON.stringify(fetchedData, null, 2));
                } else {
                    console.warn('[UserLocationTravelCmp] Failed to load data:', result.message);
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('[UserLocationTravelCmp] Error fetching data:', error);
                this.isLoading = false;
            });
        console.log('[UserLocationTravelCmp] Exit - loadTravelDataForUser method executed');
    }

    // Handle changes in month combobox
    handleMonthChange(event) {
        this.currentMonth = Number(event.detail.value); // Get selected month (1-12)
        this.selectedMonth = this.currentMonth;
        //this.selectedMonth = this.getMonthName(this.currentMonth);
        console.log('[UserLocationTravelCmp] Month changed to:', this.selectedMonth);
        //this.loadTravelDataForUser(); // Fetch data for the new month
    }

    // Capture changes in year selection
    handleYearChange(event) {
        this.defaultStartYear = Number(event.detail.value);
        console.log('[UserLocationTravelCmp] Year changed to:', this.defaultStartYear);
        //this.loadTravelDataForUser(); // Fetch data for the new year
    }

    // Capture changes in user selection
    handleUserChange(event) {
        this.selectedUser = event.detail.value;
        console.log('[UserLocationTravelCmp] User changed to:', this.selectedUser);
    }

    // Utility to get the name of the month
    getMonthName(monthNumber) {
        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return monthNames[monthNumber - 1]; // Array is zero-based
    }

    // Initialize month options and set current month
    initializeMonthOptions() {
        console.log('[UserLocationTravelCmp] Entry - Initializing month options');
        const currentDate = new Date();
        this.currentMonth = currentDate.getMonth() + 1; // Get current month (1-12)
        this.selectedMonth = this.getMonthName(this.currentMonth);
        this.selectedMonth = this.currentMonth;
        console.log('initializeMonthOptions Month changed to:', this.selectedMonth);

        this.monthOptions = this.getMonthOptions(); // Load month options
        console.log('[UserLocationTravelCmp] Month options initialized:', this.monthOptions);
    }

    // Get options for the months
    getMonthOptions() {
        console.log('[UserLocationTravelCmp] Entry - Fetching month options');
        const options = [
            { label: 'January', value: 1 }, { label: 'February', value: 2 },
            { label: 'March', value: 3 }, { label: 'April', value: 4 },
            { label: 'May', value: 5 }, { label: 'June', value: 6 },
            { label: 'July', value: 7 }, { label: 'August', value: 8 },
            { label: 'September', value: 9 }, { label: 'October', value: 10 },
            { label: 'November', value: 11 }, { label: 'December', value: 12 }
        ];
        console.log('[UserLocationTravelCmp] Month options fetched:', options);
        return options;
    }

    // Set year options for the combobox
    setYearOption() {
        console.log('[UserLocationTravelCmp] Entry - Setting year options');
        let yearOptions = [];
        for (let start = 2017; start <= this.defaultStartYear; start++) {
            yearOptions.push({ label: start.toString(), value: start });
        }
        this.yearOptions = [...yearOptions];
        console.log('[UserLocationTravelCmp] Year options set:', JSON.stringify(this.yearOptions));
    }
}