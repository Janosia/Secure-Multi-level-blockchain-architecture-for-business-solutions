// Use dynamic import for chai
(async () => {
    const { expect } = await import('chai'); // Dynamic import
    const { handleTransactionRequest } = await import('../bridge.js'); // Adjust path as necessary

    describe('Bridge.js Tests', function () {
        it('should validate a correct transaction request', async function () {
            const validRequest = {
                toAddress: 'GAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', // Replace with a valid Stellar address
                amount: '1.0',
                transactionType: 'type1',
            };

            // Call handleTransactionRequest once and await its result
            const result = await handleTransactionRequest(validRequest);
            expect(result).to.be.undefined; // Adjust based on expected behavior
        });
    });
})();
