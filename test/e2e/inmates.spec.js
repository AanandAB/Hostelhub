import { test, expect } from '../lib/fixtures.js';
import { appText, reloadApp } from '../lib/flutter.js';
import { InmatesPage } from '../lib/pages/inmates.page.js';
import { AddInmatePage } from '../lib/pages/add-inmate.page.js';
import { newInmate } from '../config/testdata.js';

/**
 * Inmate onboarding end-to-end: the owner adds a new resident through the form
 * and the resident shows up on the inmates tab.
 */
test.describe('@e2e Inmates', () => {
  test('E2E-INM-01 inmates tab shows property, room and existing residents', async ({ hostelApp, hostel }) => {
    const inmate = await hostel.addInmate();
    await reloadApp(hostelApp);
    const page = new InmatesPage(hostelApp);
    await page.open();
    await page.expectLoaded(hostel.property.name);
    await page.expectRoomsSection();
    await page.expectInmateListed(inmate.name);
  });

  test('E2E-INM-02 owner adds an inmate through the UI', async ({ hostelApp, hostel }) => {
    const inmates = new InmatesPage(hostelApp);
    await inmates.open();
    await inmates.expectLoaded(hostel.property.name);
    await inmates.openAddInmate();

    const form = new AddInmatePage(hostelApp);
    await form.expectLoaded();

    const data = newInmate({ bed_no: 2, rent_amount: 7000, due_day: 10 });
    await form.selectRoom(hostel.room.room_no);
    await form.fill({
      name: data.name,
      phone: data.phone,
      email: data.email,
      bedNo: data.bed_no,
      rent: data.rent_amount,
      dueDay: data.due_day,
    });

    const before = await appText(hostelApp);
    await form.save();

    // Either a credentials dialog or the list itself proves creation.
    const after = await appText(hostelApp);
    expect(after).not.toBe(before);
    await form.dismiss();

    await inmates.open();
    await inmates.expectInmateListed(data.name);
  });

  test('E2E-INM-03 new inmate is visible to the API as well', async ({ hostelApp, hostel }) => {
    const inmates = new InmatesPage(hostelApp);
    await inmates.open();
    await inmates.openAddInmate();

    const form = new AddInmatePage(hostelApp);
    await form.expectLoaded();
    const data = newInmate({ bed_no: 3 });
    await form.selectRoom(hostel.room.room_no);
    await form.fill({ name: data.name, phone: data.phone, email: data.email, bedNo: data.bed_no, rent: data.rent_amount, dueDay: data.due_day });
    await form.save();
    await form.dismiss();

    const { inmates: list } = await hostel.api.listInmates(hostel.property.id);
    expect(list.some((i) => i.name === data.name)).toBe(true);
  });
});
