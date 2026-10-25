import { test, expect } from '../lib/fixtures.js';

/**
 * Occupancy rules regression — the capacity/bed constraints are enforced by the
 * Worker and are the easiest thing to break when onboarding code changes.
 */
test.describe('@regression Occupancy rules', () => {
  test('REG-OCC-01 a room cannot take more residents than its capacity', async ({ hostel }) => {
    const room = hostel.room; // capacity 3
    for (let bed = 1; bed <= room.capacity; bed += 1) {
      await hostel.addInmate({ bed_no: bed });
    }
    await expect(hostel.addInmate({ bed_no: 2 })).rejects.toThrow(/full|capacity/i);
  });

  test('REG-OCC-02 the same bed cannot be assigned twice', async ({ hostel }) => {
    await hostel.addInmate({ bed_no: 1 });
    await expect(hostel.addInmate({ bed_no: 1 })).rejects.toThrow(/already taken|bed/i);
  });

  test('REG-OCC-03 bed number outside 1..capacity is rejected', async ({ hostel }) => {
    await expect(hostel.addInmate({ bed_no: 99 })).rejects.toThrow(/out of range|bed/i);
  });

  test('REG-OCC-04 inmate created through the API appears in the list', async ({ hostel }) => {
    const inmate = await hostel.addInmate();
    const { inmates } = await hostel.api.listInmates(hostel.property.id);
    const found = inmates.find((i) => i.id === inmate.id);
    expect(found).toBeTruthy();
    expect(found.room_no).toBe(hostel.room.room_no);
    expect(found.bed_no).toBe(1);
  });
});
