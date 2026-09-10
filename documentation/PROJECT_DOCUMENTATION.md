# Salesforce Project Documentation

## WhatNext Vision Motors CRM

Custom CRM implementation using Salesforce Flow, Apex, Batch Apex and Scheduled Apex.

## 1 Project Overview

WhatNext Vision Motors is implemented as a custom Salesforce CRM to centralize vehicle, dealer, customer, order, test-drive, and service-request data. The project addresses delayed dealer assignment, vehicle-stock mismatches, manual test-drive follow-up, and recurring processing of pending orders.

The implementation combines declarative Salesforce tools with programmatic Apex. Record-Triggered Flows automate dealer assignment and customer reminders, while an Apex Trigger and Trigger Handler enforce stock rules. Batch Apex and Scheduled Apex provide asynchronous processing for pending orders when stock becomes available.

## 2 Objectives and Scope

### 2.1 Primary Business Objectives

- Centralize management of vehicles, authorized dealers, customers, vehicle orders, test drives, and service requests.
- Automatically assign a dealer to a pending order by matching the customer address with the dealer location.
- Prevent a confirmed order when the selected vehicle has no available stock.
- Reduce vehicle stock when an order becomes Confirmed.
- Send an automated email reminder one day before a scheduled test drive.
- Process pending orders in bulk after stock replenishment and schedule that processing to run daily.

### 2.2 Project Scope

**In-Scope:** custom objects, business fields, Lookup Relationships, custom tabs, a Lightning app, Record-Triggered Flows, Apex Trigger/Handler logic, Batch Apex, Scheduled Apex, and functional verification of completed automations.

**Not documented as implemented:** custom security profiles, role hierarchy, Dynamic Forms, data migration rules, duplicate rules, Change Sets, or Apex test classes.

## 3 Phase 1: Requirement Analysis & Planning

### 3.1 Understanding Business Requirements

The CRM workflow is centered on accurate stock handling and timely customer communication. Orders reference customers and vehicles, test drives require scheduled reminders, and order processing must remain consistent even when stock changes after an order is created.

### 3.2 Data Model Architecture

| Object | Key Fields | Relationships |
|---|---|---|
| Vehicle__c | Vehicle Model, Stock Quantity, Price, Status | Lookup to Vehicle Dealer |
| Vehicle_Dealer__c | Dealer Location, Dealer Code, Phone, Email | Referenced by Vehicle and Vehicle Order |
| Vehicle_Customer__c | Email, Phone, Address, Preferred Vehicle Type | Referenced by Order, Test Drive and Service Request |
| Vehicle_Order__c | Order Date, Status | Lookup to Vehicle Customer, Vehicle and Vehicle Dealer |
| Vehicle_Test_Drive__c | Test Drive Date, Status | Lookup to Vehicle Customer and Vehicle |
| Vehicle_Service_Request__c | Service Date, Issue Description, Status | Lookup to Vehicle Customer and Vehicle |

## 4 Phase 2: Salesforce Development - Backend & Configurations

### 4.1 Declarative Automation: Record-Triggered Flows

**Auto Assign Dealer Flow:** runs when a Vehicle Order is created with Status = Pending. It retrieves the related Vehicle Customer, reads the Address, finds a Vehicle Dealer whose Dealer Location matches that Address, and updates the Vehicle Order Dealer lookup.

**Test Drive Reminder Flow:** runs when a Vehicle Test Drive is created or updated with Status = Scheduled. A scheduled path executes one day before Test Drive Date, retrieves the related customer, and sends a reminder email.

### 4.2 Programmatic Automation: Apex & Triggers

VehicleOrderTrigger executes in before insert, before update, after insert, and after update contexts and delegates the business logic to VehicleOrderTriggerHandler. The handler blocks a Confirmed order when Stock Quantity is zero or less and reduces stock when an order becomes Confirmed.

### 4.3 Asynchronous Apex: Batch & Scheduled Jobs

VehicleOrderBatch queries Pending Vehicle Orders, checks related vehicle stock, and changes eligible orders to Confirmed. VehicleOrderBatchScheduler runs the batch with a batch size of 50. Daily Vehicle Order Processing is scheduled with the CRON expression `0 0 0 * * ?` for midnight execution.

## 5 Phase 3: UI/UX Development & Customization

### 5.1 Lightning App & Tab Setup

A Lightning app named WhatNext Vision Motors was created through App Manager. Custom Object Tabs were created for Vehicle Customers, Vehicle Dealers, Vehicle Orders, Vehicles, Vehicle Service Requests, and Vehicle Test Drives.

## 6 Phase 4: Functional Testing

| Component | Test Scenario | Result |
|---|---|---|
| Apex Trigger | Confirm order for a vehicle with Stock Quantity = 0 | Passed - save blocked with custom error |
| Apex Trigger | Confirm an order after stock is available | Passed - stock reduced |
| Record Flow | Create a Pending order with related customer/location data | Activated / Configured |
| Record Flow | Create a Scheduled Test Drive for the next day | Passed - reminder email received |
| Scheduled Apex | Register Daily Vehicle Order Processing | Passed - scheduled for midnight |
| Batch Apex | Process Pending orders after replenishment | Configured |

## 7 Conclusion

The WhatNext Vision Motors CRM implementation combines Salesforce configuration, Flow automation, and Apex development for the core automotive workflow. The custom data model supports vehicles, dealers, customers, orders, test drives, and service requests. Two Record-Triggered Flows automate dealer assignment and test-drive reminders. The Apex Trigger Handler enforces stock validation and stock reduction, while Batch Apex and Scheduled Apex provide recurring processing for pending orders.
